import XCTest
import CoreData

@testable import Wilt

final class TrackHistoryCacheTest: XCTestCase {
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(
            from: [Bundle(for: type(of: self))]
        )!
        return managedObjectModel
    }()
    private lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "TrackHistoryCacheTest",
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
    private var cache: TrackHistoryCache!

    override func setUp() {
        FakeData.historyItems.forEach {
            let item = TrackHistoryEntity(
                entity: NSEntityDescription.entity(
                    forEntityName: "TrackHistoryEntity",
                    in: mockPersistentContainer.viewContext
                )!,
                insertInto: mockPersistentContainer.viewContext
            )
            item.artistName = $0.artistName
            item.songName = $0.songName
            item.date = $0.date
            item.trackID = $0.trackID
            item.imageURL = $0.imageURL
            item.externalURL = $0.externalURL
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        cache = try! TrackHistoryCache(
            viewContext: mockPersistentContainer.viewContext
        )
    }

    override func tearDown() {
        clearAllData()
    }

    private func clearAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "TrackHistoryEntity"
        )
        let items = try! mockPersistentContainer.viewContext.fetch(fetchRequest)
        for case let item as NSManagedObject in items {
            mockPersistentContainer.viewContext.delete(item)
        }
        try! mockPersistentContainer.viewContext.save()
    }

    func testItems() {
        XCTAssertEqual(FakeData.historyItems, cache.items)
    }

    func testItemsSorts() {
        clearAllData()
        // Insert in reverse order
        FakeData.historyItems.reversed().forEach {
            let item = TrackHistoryEntity(context: mockPersistentContainer.viewContext)
            item.songName = $0.songName
            item.artistName = $0.artistName
            item.date = $0.date
            item.imageURL = $0.imageURL
            item.externalURL = $0.externalURL
            item.trackID = $0.trackID
            mockPersistentContainer.viewContext.insert(item)
        }
        try! mockPersistentContainer.viewContext.save()
        // Ensure everything comes out in the correct order
        XCTAssertEqual(FakeData.historyItems, cache.items)
    }

    func testItemsWithQuery() throws {
        let expected = [
            TrackHistoryData(
                songName: "Angelina",
                artistName: "Pinegrove",
                date: FakeData.formatter.date(from: "2019-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            TrackHistoryData(
                songName: "Making Breakfast",
                artistName: "Twin Peaks",
                date: FakeData.formatter.date(from: "2018-09-01")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
        ]
        try cache.setArtistQuery(artistQuery: "P")
        XCTAssertEqual(expected, cache.items)
    }

    func testItemsWithQueryIsCaseInsensitive() throws {
        let expected = [
            TrackHistoryData(
                songName: "Angelina",
                artistName: "Pinegrove",
                date: FakeData.formatter.date(from: "2019-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            TrackHistoryData(
                songName: "Making Breakfast",
                artistName: "Twin Peaks",
                date: FakeData.formatter.date(from: "2018-09-01")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
        ]
        // Lowercase p
        try cache.setArtistQuery(artistQuery: "p")
        XCTAssertEqual(expected, cache.items)
    }

    func testItemsWithQueryIgnoringThe() throws {
        let expected = [
            TrackHistoryData(
                songName: "Making Breakfast",
                artistName: "Twin Peaks",
                date: FakeData.formatter.date(from: "2018-09-01")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
            // Ignores "Show Me The Body"
            TrackHistoryData(
                songName: "Black Nails",
                artistName: "Tierra Whack",
                date: FakeData.formatter.date(from: "2018-01-10")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://notarealimageurl.notreal.net")!,
                trackID: "not_a_real_track_id"
            ),
        ]
        try cache.setArtistQuery(artistQuery: "T")
        XCTAssertEqual(expected, cache.items)
    }

    func testBatchInsert() {
        let newItems = [
            TrackHistoryData(
                songName: "BALD",
                artistName: "JPEGMAFIA",
                date: FakeData.formatter.date(from: "2013-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://anexternalurlok.xyz")!,
                trackID: "notarealID123"
            ),
            TrackHistoryData(
                songName: "Golden Days",
                artistName: "Whitney",
                date: FakeData.formatter.date(from: "2012-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://theexternalurlok.xyz")!,
                trackID: "anotherFakeIDhey"
            ),
        ]
        do {
            try cache.batchInsert(items: newItems)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(FakeData.historyItems + newItems, cache.items)
    }

    func testBatchInsertIgnoresDuplicates() {
        let newItems = [
            // This item will be added as usual
            TrackHistoryData(
                songName: "BALD",
                artistName: "JPEGMAFIA",
                date: FakeData.formatter.date(from: "2013-02-25")!,
                imageURL: URL(string: "http://notarealimageurl.notreal.net")!,
                externalURL: URL(string: "http://anexternalurlok.xyz")!,
                trackID: "notarealID123"
            ),
            FakeData.historyItems[1]
        ]
        do {
            try cache.batchInsert(items: newItems)
        } catch {
            XCTFail()
        }
        XCTAssertEqual(
            FakeData.historyItems + [newItems[0]],
            cache.items
        )
    }
}
