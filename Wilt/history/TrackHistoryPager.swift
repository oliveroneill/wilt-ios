/// Requests per-song play history data from Wilt in pages
final class TrackHistoryPager {
    private let api: WiltAPI
    private let dao: TrackHistoryDao
    private let pageSize: Int

    /// Create a TrackHistoryPager
    ///
    /// - Parameters:
    ///   - api: The API to make requests to
    ///   - dao: Where responses should be inserted
    ///   - pageSize: The number of items that will make up a page
    init(api: WiltAPI, dao: TrackHistoryDao, pageSize: Int) {
        self.api = api
        self.dao = dao
        self.pageSize = pageSize
    }

    func onZeroItemsLoaded(artistSearchQuery: String?,
                           completionHandler: @escaping PagerCompletionHandler) {
        let end = Date().timeIntervalSince1970
        getTrackHistory(
            before: Int64(end),
            artistSearchQuery: artistSearchQuery,
            completionHandler: completionHandler,
            firstLoad: true
        )
    }

    func loadLaterPage(latestItem: TrackHistoryData,
                       artistSearchQuery: String?,
                       completionHandler: @escaping PagerCompletionHandler) {
        let after = latestItem.date.timeIntervalSince1970
        getTrackHistory(
            after: Int64(after),
            artistSearchQuery: artistSearchQuery,
            completionHandler: completionHandler
        )
    }

    func loadEarlierPage(earliestItem: TrackHistoryData,
                         artistSearchQuery: String?,
                         completionHandler: @escaping PagerCompletionHandler) {
        let before = earliestItem.date.timeIntervalSince1970
        getTrackHistory(
            before: Int64(before),
            artistSearchQuery: artistSearchQuery,
            completionHandler: completionHandler
        )
    }

    private func getTrackHistory(before: Int64,
                                 artistSearchQuery: String?,
                                 completionHandler: @escaping PagerCompletionHandler,
                                 firstLoad: Bool = false) {
        api.getTrackHistory(
            limit: pageSize,
            before: before,
            artistSearchQuery: artistSearchQuery
        ) { [weak self] in
            guard let self = self else { return }
            self.handleResponse(
                result: $0,
                firstLoad: firstLoad,
                completionHandler: completionHandler
            )
        }
    }

    private func getTrackHistory(after: Int64,
                                 artistSearchQuery: String?,
                                 completionHandler: @escaping PagerCompletionHandler,
                                 firstLoad: Bool = false) {
        api.getTrackHistory(
            limit: pageSize,
            after: after,
            artistSearchQuery: artistSearchQuery
        ) { [weak self] in
            guard let self = self else { return }
            self.handleResponse(
                result: $0,
                firstLoad: firstLoad,
                completionHandler: completionHandler
            )
        }
    }

    private func handleResponse(result: Result<[TrackHistoryData], Error>,
                                firstLoad: Bool = false,
                                completionHandler: @escaping PagerCompletionHandler) {
        do {
            let items = try result.get()
            // If this is the initial load and there's no data available
            // then we should update the UI
            guard !firstLoad || !items.isEmpty else {
                completionHandler(.success(0))
                return
            }
            try self.dao.batchInsert(items: items)
            completionHandler(.success(items.count))
        } catch {
            completionHandler(.failure(error))
        }
    }
}
