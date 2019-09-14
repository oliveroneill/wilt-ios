import XCTest
import CoreData

@testable import Wilt

class PlayHistoryCacheTest: XCTestCase {
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(
            from: [Bundle(for: type(of: self))]
        )!
        return managedObjectModel
    }()
    private lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "PlayHistoryCacheTest",
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
    private var cache: PlayHistoryCache!

    override func setUp() {
        FakeData.items.forEach {
            let item = TopArtist(
                entity: NSEntityDescription.entity(
                    forEntityName: "TopArtist",
                    in: mockPersistentContainer.viewContext
                )!,
                insertInto: mockPersistentContainer.viewContext
            )
            item.topArtist = $0.topArtist
            item.count = $0.count
            item.date = $0.date
            item.week = $0.week
            item.imageURL = $0.imageURL
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        cache = try! PlayHistoryCache(
            viewContext: mockPersistentContainer.viewContext
        )
    }

    override func tearDown() {
        clearAllData()
    }

    private func clearAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "TopArtist"
        )
        let items = try! mockPersistentContainer.viewContext.fetch(fetchRequest)
        for case let item as NSManagedObject in items {
            mockPersistentContainer.viewContext.delete(item)
        }
        try! mockPersistentContainer.viewContext.save()
    }

    func testItems() {
        XCTAssertEqual(FakeData.items, cache.items)
    }

    func testItemsSorts() {
        clearAllData()
        // Insert in reverse order
        FakeData.items.reversed().forEach {
            let item = TopArtist(context: mockPersistentContainer.viewContext)
            item.topArtist = $0.topArtist
            item.count = $0.count
            item.date = $0.date
            item.week = $0.week
            item.imageURL = $0.imageURL
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        // Ensure everything comes out in the correct order
        XCTAssertEqual(FakeData.items, cache.items)
    }

    func testBatchUpsert() {
        let newItems = [
            TopArtistData(
                topArtist: "JPEGMAFIA",
                count: 16,
                date: FakeData.formatter.date(from: "2013-02-25")!,
                week: "09-2013",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Whitney",
                count: 23,
                date: FakeData.formatter.date(from: "2012-02-25")!,
                week: "09-2012",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
        ]
        do {
            try cache.batchUpsert(items: newItems)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(FakeData.items + newItems, cache.items)
    }

    func testBatchUpsertWithExistingItems() {
        let newItems = [
            // This item will be added as usual
            TopArtistData(
                topArtist: "JPEGMAFIA",
                count: 16,
                date: FakeData.formatter.date(from: "2013-02-25")!,
                week: "09-2013",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
            TopArtistData(
                topArtist: "Whitney",
                count: 23,
                date: FakeData.formatter.date(from: "2018-12-25")!,
                // This one has the same week as the second element in
                // FakeData.items
                week: "52-2018",
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!
            ),
        ]
        do {
            try cache.batchUpsert(items: newItems)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(
            [FakeData.items[0]] + [newItems[1]] + FakeData.items.dropFirst(2) + [newItems[0]],
            cache.items
        )
    }
}
