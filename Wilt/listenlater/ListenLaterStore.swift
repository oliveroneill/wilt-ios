import CoreData

struct ListenLaterArtist: Equatable {
    let name: String
    let externalURL: URL
    let imageURL: URL?
}

extension ListenLaterArtistEntity {
    /// A helper function to convert the Core Data representation into a plain
    /// Swift object format
    ///
    /// - Returns: A struct representation of the Core Data format
    func toData() -> ListenLaterArtist {
        // We'll error if any of the values are nil. This shouldn't occur but
        // I wonder if there's a better way to handle this
        guard let name = name, let externalURL = externalURL else {
                fatalError("Unexpected nil stored in Core Data")
        }
        return ListenLaterArtist(
            name: name,
            externalURL: externalURL,
            imageURL: imageURL
        )
    }
}

/// A protocol for accessing and inserting into the persistence layer
protocol ListenLaterDao: class {
    /// The items available in the store
    var items: [ListenLaterArtist] { get }
    /// Set this to receive updates when items are added or removed
    var onDataChange: (() -> Void)? { get set }
    /// Insert an item
    ///
    /// - Parameter items: The item to insert
    /// - Throws: If the operation fails
    func insert(item: ListenLaterArtist) throws
    func contains(name: String) throws -> Bool
    func delete(name: String) throws
}

enum ListenLaterStoreError: Error {
    case unexpectedUnfinishedOperation
}

/// An implementation of ListenLaterDao using CoreData and
/// NSFetchedResultsController
final class ListenLaterStore: NSObject, ListenLaterDao {
    private let viewContext: NSManagedObjectContext
    private lazy var updateContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(
            concurrencyType: .privateQueueConcurrencyType
        )
        managedObjectContext.parent = viewContext
        return managedObjectContext
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<ListenLaterArtistEntity> = {
        let fetchRequest: NSFetchRequest<ListenLaterArtistEntity> = ListenLaterArtistEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
        fetchRequest.fetchBatchSize = 10
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: "listen_later_store"
        )
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    /// The items stored for later listening. These will be read out in batches of 10
    var items: [ListenLaterArtist] {
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

    func insert(item: ListenLaterArtist) throws {
        // performAndWait can't throw, so we need to store the error and
        // throw it at the end
        var insertError: Error?
        updateContext.performAndWait {
            do {
                try store(item: item)
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

    private func store(item: ListenLaterArtist) throws {
        // There's no primary keys in Core Data, so we have to check each
        // item to see if it already exists
        guard let found = try get(name: item.name) else {
                // We couldn't find an existing item so we just insert it
                let stored = ListenLaterArtistEntity(context: updateContext)
                stored.name = item.name
                stored.imageURL = item.imageURL
                stored.externalURL = item.externalURL
                updateContext.insert(stored)
                return
        }
        // We found an existing item so just update all of it's properties
        found.name = item.name
        found.imageURL = item.imageURL
        found.externalURL = item.externalURL
    }

    private func get(name: String) throws -> ListenLaterArtistEntity? {
        let fetchRequest: NSFetchRequest<ListenLaterArtistEntity> = ListenLaterArtistEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.fetchLimit = 1
        let fetchResult = try updateContext.execute(fetchRequest)
        let result = fetchResult as? NSAsynchronousFetchResult<NSFetchRequestResult>
        return result?.finalResult?.first as? ListenLaterArtistEntity
    }

    func contains(name: String) throws -> Bool {
        // performAndWait can't throw, so we need to store the error and
        // throw it at the end
        var result: Result<Bool, Error>?
        updateContext.performAndWait {
            do {
                result = .success(try get(name: name) != nil)
            } catch let error as NSError {
                let queryError = NSError(
                    domain: error.domain,
                    code: error.code,
                    // Store as string so that we don't have to worry about
                    // thread-safety
                    userInfo: ["error": "\(error.userInfo)"]
                )
                result = .failure(queryError)
            }
        }
        guard let r = result else {
            throw ListenLaterStoreError.unexpectedUnfinishedOperation
        }
        return try r.get()
    }

    func delete(name: String) throws {
        // performAndWait can't throw, so we need to store the error and
        // throw it at the end
        var queryError: Error?
        updateContext.performAndWait {
            do {
                guard let found = try get(name: name) else {
                    return
                }
                updateContext.delete(found)
                try updateContext.save()
            } catch let error as NSError {
                queryError = NSError(
                    domain: error.domain,
                    code: error.code,
                    // Store as string so that we don't have to worry about
                    // thread-safety
                    userInfo: ["error": "\(error.userInfo)"]
                )
            }
        }
        if let error = queryError {
            throw error
        }
    }
}

extension ListenLaterStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Persist whatever this change is
        DispatchQueue.main.async { [weak self] in
            try? self?.viewContext.save()
        }
        onDataChange?()
    }
}
