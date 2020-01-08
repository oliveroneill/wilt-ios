import XCTest
import CoreData

@testable import Wilt

final class ListenLaterStoreTest: XCTestCase {
    private lazy var expectedItems: [ListenLaterArtist] = {
        FakeData.items.map {
            ListenLaterArtist(
                name: $0.topArtist,
                externalURL: $0.externalURL,
                imageURL: $0.imageURL
            )
        }.sorted {
            $0.name < $1.name
        }
    }()
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(
            from: [Bundle(for: type(of: self))]
        )!
        return managedObjectModel
    }()
    private lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "ListenLaterStoreTest",
            managedObjectModel: self.managedObjectModel
        )
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores {
            precondition($0.type == NSInMemoryStoreType)
            if let error = $1 {
                fatalError("Create an in-memory coordinator failed \(error)")
            }
        }
        return container
    }()
    private var store: ListenLaterStore!

    override func setUp() {
        expectedItems.forEach {
            let item = ListenLaterArtistEntity(
                entity: NSEntityDescription.entity(
                    forEntityName: "ListenLaterArtistEntity",
                    in: mockPersistentContainer.viewContext
                )!,
                insertInto: mockPersistentContainer.viewContext
            )
            item.name = $0.name
            item.imageURL = $0.imageURL
            item.externalURL = $0.externalURL
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        store = try! ListenLaterStore(
            viewContext: mockPersistentContainer.viewContext
        )
    }

    override func tearDown() {
        clearAllData()
    }

    private func clearAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "ListenLaterArtistEntity"
        )
        let items = try! mockPersistentContainer.viewContext.fetch(fetchRequest)
        for case let item as NSManagedObject in items {
            mockPersistentContainer.viewContext.delete(item)
        }
        try! mockPersistentContainer.viewContext.save()
    }

    func testItems() {
        XCTAssertEqual(expectedItems, store.items)
    }

    func testItemsSorts() {
        clearAllData()
        // Insert in reverse order
        expectedItems.reversed().forEach {
            let item = ListenLaterArtistEntity(context: mockPersistentContainer.viewContext)
            item.name = $0.name
            item.imageURL = $0.imageURL
            item.externalURL = $0.externalURL
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        // Ensure everything comes out in the correct order
        XCTAssertEqual(expectedItems, store.items)
    }

    func testInsert() {
        let newItem = ListenLaterArtist(
            name: "Yes",
            externalURL: URL(string: "http://anexternalurlok.xyz")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        do {
            try store.insert(item: newItem)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(expectedItems + [newItem], store.items)
    }

    func testInsertWithExistingItem() {
        let newItem = ListenLaterArtist(
            name: "Pinegrove",
            externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
            imageURL: URL(string: "http://notarealimageurl.notreal.net")!
        )
        do {
            try store.insert(item: newItem)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(expectedItems, store.items)
    }
}
