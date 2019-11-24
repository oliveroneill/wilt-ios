import XCTest
import CoreData

@testable import Wilt

final class ProfileCacheTest: XCTestCase {
    enum ProfileCacheTestError: Error {
        case testError
    }
    private let error = ProfileCacheTestError.testError

    private lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(
            from: [Bundle(for: type(of: self))]
        )!
        return managedObjectModel
    }()
    private lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(
            name: "ProfileCacheTest",
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
    private lazy var context: NSManagedObjectContext = {
        return mockPersistentContainer.newBackgroundContext()
    }()
    private var cache: ProfileCache!

    override func tearDown() {
        clearAllData()
    }

    private func clearAllData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "TopArtistInfoEntity"
        )
        let items = try! context.fetch(fetchRequest)
        for case let item as NSManagedObject in items {
            context.delete(item)
        }
        try! context.save()
    }

    private func storeArtist(artist: TopArtistInfo, timeRange: String,
                             index: Int, storedAt: Date) {
        context.performAndWait {
            let item = TopArtistInfoEntity(
                entity: NSEntityDescription.entity(
                    forEntityName: "TopArtistInfoEntity",
                    in: context
                )!,
                insertInto: context
            )
            item.name = artist.name
            item.count = artist.count
            item.lastPlayed = artist.lastPlayed
            item.imageURL = artist.imageURL
            item.externalURL = artist.externalURL
            item.lastUpdated = storedAt
            item.timeRange = timeRange
            item.index = Int32(index)
            context.insert(item)
            try! context.save()
        }
    }

    private func storeTrack(track: TopTrackInfo, timeRange: String,
                            index: Int, storedAt: Date) {
        context.performAndWait {
            let item = TopTrackInfoEntity(
                entity: NSEntityDescription.entity(
                    forEntityName: "TopTrackInfoEntity",
                    in: context
                )!,
                insertInto: context
            )
            item.name = track.name
            item.totalPlayTimeSeconds = Int64(track.totalPlayTime)
            item.lastPlayed = track.lastPlayed
            item.imageURL = track.imageURL
            item.externalURL = track.externalURL
            item.lastUpdated = storedAt
            item.timeRange = timeRange
            item.index = Int32(index)
            context.insert(item)
            try! context.save()
        }
    }

    func testTopArtistUsesNetwork() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topArtist(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopArtistUsesCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeArtist(
            artist: expected,
            timeRange: timeRange,
            index: index,
            storedAt: Date()
        )
        cache = ProfileCache(
            backgroundContext: mockPersistentContainer.newBackgroundContext(),
            networkAPI: FakeWiltAPI()
        )
        let exp = expectation(description: "Should return a value")
        cache.topArtist(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopArtistUsesNetworkOnExpiredCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeArtist(
            artist: expected,
            timeRange: timeRange,
            index: index,
            // It's been in cache for 10 weeks
            storedAt: Date().minusWeeks(10)
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topArtist(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopArtistUpsertsOnExpiredCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopArtistInfo(
            name: "(Sandy) Alex G",
            count: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeArtist(
            artist: expected,
            timeRange: timeRange,
            index: index,
            // It's been in cache for 10 weeks
            storedAt: Date().minusWeeks(10)
        )
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topArtist(timeRange: timeRange, index: index) { _ in
            defer { exp.fulfill() }
            self.cache.topArtist(timeRange: timeRange, index: index) { _ in
                XCTAssertEqual(1, api.topArtistCalls.count)
            }
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopArtistNetworkError() {
        let timeRange = "short_term"
        let index = 32
        let api = FakeWiltAPI(
            topArtistResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .failure(error)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topArtist(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .failure(error) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(self.error, error as? ProfileCacheTestError)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopTrackUsesNetwork() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopTrackInfo(
            name: "(Sandy) Alex G",
            totalPlayTime: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topTrack(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopTrackUsesCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopTrackInfo(
            name: "(Sandy) Alex G",
            totalPlayTime: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeTrack(
            track: expected,
            timeRange: timeRange,
            index: index,
            storedAt: Date()
        )
        cache = ProfileCache(
            backgroundContext: mockPersistentContainer.newBackgroundContext(),
            networkAPI: FakeWiltAPI()
        )
        let exp = expectation(description: "Should return a value")
        cache.topTrack(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopTrackUsesNetworkOnExpiredCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopTrackInfo(
            name: "(Sandy) Alex G",
            totalPlayTime: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeTrack(
            track: expected,
            timeRange: timeRange,
            index: index,
            // It's been in cache for 10 weeks
            storedAt: Date().minusWeeks(10)
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topTrack(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .success(artist) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(expected, artist)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopTrackUpsertsOnExpiredCache() {
        let timeRange = "short_term"
        let index = 32
        let expected = TopTrackInfo(
            name: "(Sandy) Alex G",
            totalPlayTime: 354,
            lastPlayed: Date().minusWeeks(6),
            imageURL: URL(string: "http://notarealdomainyeah.com/x/y")!,
            externalURL: URL(string: "http://notarealdomainok.com/x/y")!
        )
        storeTrack(
            track: expected,
            timeRange: timeRange,
            index: index,
            // It's been in cache for 10 weeks
            storedAt: Date().minusWeeks(10)
        )
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .success(expected)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topTrack(timeRange: timeRange, index: index) { _ in
            self.cache.topTrack(timeRange: timeRange, index: index) { _ in
                defer { exp.fulfill() }
                XCTAssertEqual(1, api.topTrackCalls.count)
            }
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testTopTrackNetworkError() {
        let timeRange = "short_term"
        let index = 32
        let api = FakeWiltAPI(
            topTrackResult: [
                TopSomethingRequest(timeRange: timeRange, index: index): .failure(error)
            ]
        )
        cache = ProfileCache(
            backgroundContext: context,
            networkAPI: api
        )
        let exp = expectation(description: "Should return a value")
        cache.topTrack(timeRange: timeRange, index: index) {
            defer { exp.fulfill() }
            guard case let .failure(error) = $0 else {
                XCTFail()
                return
            }
            XCTAssertEqual(self.error, error as? ProfileCacheTestError)
        }
        waitForExpectations(timeout: 1) {
            if let error = $0 {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
