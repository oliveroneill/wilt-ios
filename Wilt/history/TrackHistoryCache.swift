import CoreData

/// A protocol for accessing and inserting into the persistence layer
protocol TrackHistoryDao: class {
    /// The items available in cache
    var items: [TrackHistoryData] { get }
    /// Set this to receive updates when the cache changes
    var onDataChange: (() -> Void)? { get set }
    /// Insert items if they don't already exist
    ///
    /// - Parameter items: The items to upsert
    /// - Throws: If the operation fails
    func batchInsert(items: [TrackHistoryData]) throws
}

/// An implementation of TrackHistoryDao using CoreData and
/// NSFetchedResultsController
final class TrackHistoryCache: NSObject, TrackHistoryDao {
    private let viewContext: NSManagedObjectContext
    private lazy var updateContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        managedObjectContext.parent = viewContext
        return managedObjectContext
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackHistoryEntity> = {
        let fetchRequest: NSFetchRequest<TrackHistoryEntity> = TrackHistoryEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            // ascending false equals descending apparently
            NSSortDescriptor(key: "date", ascending: false)
        ]
        fetchRequest.fetchBatchSize = 10
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: "track_history_cache"
        )
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    /// The items in cache. These will be read out in batches of 10
    var items: [TrackHistoryData] {
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

    func batchInsert(items: [TrackHistoryData]) throws {
        guard !items.isEmpty else {
            return
        }
        // performAndWait can't throw, so we need to store the error and
        // throw it at the end
        var insertError: Error?
        updateContext.performAndWait {
            do {
                try insert(items: items)
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

    private func insert(items: [TrackHistoryData]) throws {
        try items.forEach {
            let fetchRequest: NSFetchRequest<TrackHistoryEntity> = TrackHistoryEntity.fetchRequest()
            // We use trackID and date to identify a unique track listen
            fetchRequest.predicate = NSPredicate(
                format: "trackID == %@ AND date == %@",
                $0.trackID,
                $0.date as NSDate
            )
            fetchRequest.fetchLimit = 1
            // If we find the item was already there, then we don't insert again
            let fetchResult = try updateContext.execute(fetchRequest)
            if let result = fetchResult as? NSAsynchronousFetchResult<NSFetchRequestResult>,
                (result.finalResult?.count ?? 0) > 0 {
                return
            }
            let item = TrackHistoryEntity(context: updateContext)
            item.artistName = $0.artistName
            item.songName = $0.songName
            item.date = $0.date
            item.imageURL = $0.imageURL
            item.externalURL = $0.externalURL
            item.trackID = $0.trackID
            updateContext.insert(item)
        }
    }
}

extension TrackHistoryCache: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Persist whatever this change is
        DispatchQueue.main.async { [weak self] in
            try? self?.viewContext.save()
        }
        onDataChange?()
    }
}
