import CoreData

/// A Core Data wrapper for accessing the database
class WiltDatabase {
    private let container = NSPersistentContainer(name: "Wilt")
    private var persistenceLoaded = false
    private var persistenceLoadError: NSError?

    private func loadPersistentStore(
        onLoadComplete: @escaping (Error?) -> Void
    ) {
        guard !persistenceLoaded else {
            // Don't reload if we've already loaded
            onLoadComplete(persistenceLoadError)
            return
        }
        container.loadPersistentStores { [unowned self] (_, error) in
            self.persistenceLoaded = true
            self.persistenceLoadError = error as NSError?
            onLoadComplete(error)
        }
    }

    /// Get the viewContext from Core Data
    ///
    /// - Parameter onContextLoaded: Called when we've loaded the context or
    /// failed
    func loadContext(
        onContextLoaded: @escaping (Result<NSManagedObjectContext, Error>) -> Void
    ) {
        loadPersistentStore { [unowned self] in
            if let error = $0 {
                onContextLoaded(.failure(error))
                return
            }
            onContextLoaded(.success(self.container.viewContext))
        }
    }
}
