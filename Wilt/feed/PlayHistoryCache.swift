import CoreData

/// A protocol for accessing and inserting into the persistence layer
protocol PlayHistoryDao: class {
    /// The items available in cache
    var items: [TopArtistData] { get }
    /// Set this to receive updates when the cache changes
    var onDataChange: (() -> Void)? { get set }
    /// Upsert a set of items. This will update existing items if they already
    /// exist based on the `week` value in `TopArtistData`
    ///
    /// - Parameter items: The items to upsert
    /// - Throws: If the operation fails
    func batchUpsert(items: [TopArtistData]) throws
}

/// An implementation of PlayHistoryDao using CoreData and
/// NSFetchedResultsController
class PlayHistoryCache: NSObject, PlayHistoryDao {
    private let viewContext: NSManagedObjectContext
    private lazy var updateContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        managedObjectContext.parent = viewContext
        return managedObjectContext
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<TopArtist> = {
        let fetchRequest: NSFetchRequest<TopArtist> = TopArtist.fetchRequest()
        fetchRequest.sortDescriptors = [
            // ascending false equals descending apparently
            NSSortDescriptor(key: "date", ascending: false)
        ]
        fetchRequest.fetchBatchSize = 10
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: "play_history_cache"
        )
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    /// The items in cache. These will be read out in batches of 10
    var items: [TopArtistData] {
        return fetchedResultsController.fetchedObjects!.lazy.map { $0.toData() }
    }
    /// Set this to receive updates when the cache changes
    var onDataChange: (() -> Void)?

    /// Create a Core Data cache for play history
    ///
    /// - Parameter viewContext: The context where the database operations
    /// should take place
    /// - Throws: If we're unable to fetch the contents of the cache
    init(viewContext: NSManagedObjectContext) throws {
        self.viewContext = viewContext
        super.init()
        try fetchedResultsController.performFetch()
    }

    func batchUpsert(items: [TopArtistData]) throws {
        guard !items.isEmpty else {
            return
        }
        // performAndWait can't throw, so we need to store the error and
        // throw it at the end
        var insertError: Error?
        updateContext.performAndWait {
            do {
                try upsert(items: items)
            } catch let error as NSError {
                insertError = NSError(
                    domain: error.domain,
                    code: error.code,
                    // Store as string so that we don't have to worry about
                    // thread-safety
                    userInfo: ["error": "\(error.userInfo)"]
                )
            }
            // Independently save, so that this will happen regardless of errors
            do {
                try updateContext.save()
            } catch let error as NSError {
                insertError = NSError(
                    domain: error.domain,
                    code: error.code,
                    // Store as string so that we don't have to worry about
                    // thread-safety
                    userInfo: ["error": "\(error.userInfo)"]
                )
            }
        }
        if let error = insertError {
            throw error
        }
    }

    private func upsert(items: [TopArtistData]) throws {
        try items.forEach {
            // There's no primary keys in Core Data, so we have to check each
            // item to see if it already exists. This seems bad but I couldn't
            // find a better way
            let fetchRequest: NSFetchRequest<TopArtist> = TopArtist.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "week == %@", $0.week)
            fetchRequest.fetchLimit = 1
            let fetchResult = try updateContext.execute(fetchRequest)
            guard let result = fetchResult as? NSAsynchronousFetchResult<NSFetchRequestResult>,
                let found = result.finalResult?.first as? TopArtist else {
                    // We couldn't find an existing item so we just insert it
                    let item = TopArtist(context: updateContext)
                    item.topArtist = $0.topArtist
                    item.count = $0.count
                    item.date = $0.date
                    item.week = $0.week
                    item.imageURL = $0.imageURL
                    item.externalURL = $0.externalURL
                    updateContext.insert(item)
                    return
            }
            // We found an existing item so just update all of it's properties
            found.topArtist = $0.topArtist
            found.count = $0.count
            found.date = $0.date
            found.week = $0.week
            found.imageURL = $0.imageURL
            found.externalURL = $0.externalURL
        }
    }
}

extension PlayHistoryCache: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Persist whatever this change is
        DispatchQueue.main.async { [weak self] in
            try? self?.viewContext.save()
        }
        onDataChange?()
    }
}
