/// Called when the next page load operation is complete. This will signal
/// success or failure of the load based on the Result. On success, you'll
/// receive the total number of items inserted or updated in cache
typealias PagerCompletionHandler = (Result<Int, Error>) -> Void

/// Requests play history data from Wilt in pages. A single item will be
/// an aggregate of a week's worth of plays
class PlayHistoryPager {
    private let api: WiltAPI
    private let dao: PlayHistoryDao
    private let pageSize: Int
    /// Keep track of whether the current week has been refreshed, so that we
    /// can update it once. We can't always update it because we get stuck in a
    /// loop calling [onItemAtFrontLoaded]. This flag should be good enough to
    /// just update the current week once every time the app is started
    private var refreshedCurrentWeek = false
    /// We need to keep track of whether we're just refreshing the current week,
    /// so that we don't unnecessarily try and load the next page
    private var refreshingCurrentWeek = false

    /// Create a PlayHistoryPager
    ///
    /// - Parameters:
    ///   - api: The API to make requests to
    ///   - dao: Where responses should be inserted
    ///   - pageSize: The number of items that will make up a page
    init(api: WiltAPI, dao: PlayHistoryDao, pageSize: Int) {
        self.api = api
        self.dao = dao
        self.pageSize = pageSize
    }

    func onZeroItemsLoaded(completionHandler: @escaping PagerCompletionHandler) {
        let endDate = Date()
            // Ensure requests are always run from the start of the week to
            // avoid missing earlier plays
            .startOfWeek
            // The last date we'll request from is one week ahead of now. We
            // add one week since otherwise the query might not include the
            // current week
            .plusWeeks(1)
        let end = endDate.startOfDay.timeIntervalSince1970
        // Each page is a week, so we subtract weeks to decide what to request
        // Increasing the page size seems to fix scrolling issues
        let weeksToRequest = pageSize * 2
        let startDate = endDate.minusWeeks(weeksToRequest)
        let start = startDate.startOfDay.timeIntervalSince1970
        topArtists(
            start: Int64(start),
            end: Int64(end),
            completionHandler: completionHandler,
            firstLoad: true
        )
    }

    func loadLaterPage(latestItem: TopArtistData,
                       completionHandler: @escaping PagerCompletionHandler) {
        // If we've just refreshed the current week then don't try and load
        // another page
        guard !refreshingCurrentWeek else {
            // Next load we can try again
            refreshingCurrentWeek = false
            completionHandler(.success(0))
            return
        }
        // Ensure requests are always run from the start of the week to avoid
        // missing earlier plays
        let date = latestItem.date.startOfWeek
        // In most cases date will be the current week and we should refresh
        // this since it will change before the week ends. We'll only refresh
        // this once to avoid constantly refreshing and after that we'll skip
        // this week
        let startDate = refreshedCurrentWeek ? date.plusWeeks(1) : date
        // Indicate that we're refreshing the current week
        if !refreshedCurrentWeek { refreshingCurrentWeek = true }
        refreshedCurrentWeek = true
        let start = startDate.startOfDay.timeIntervalSince1970
        // Each page is a week, so we subtract weeks to decide what to request
        let endDate = startDate.plusWeeks(pageSize)
        let end = endDate.startOfDay.timeIntervalSince1970
        topArtists(
            start: Int64(start),
            end: Int64(end),
            completionHandler: completionHandler
        )
    }

    func loadEarlierPage(earliestItem: TopArtistData,
                         completionHandler: @escaping PagerCompletionHandler) {
        // Ensure requests are always run from the start of
        // the week to avoid missing
        // earlier plays
        let date = earliestItem.date.startOfWeek
        // Subtract 1 week so that we don't include the week we've already got
        let endDate = date.minusWeeks(1)
        let end = endDate.startOfDay.timeIntervalSince1970
        // Each page is a week, so we subtract weeks to decide what to request
        let startDate = endDate.minusWeeks(pageSize)
        let start = startDate.startOfDay.timeIntervalSince1970
        topArtists(
            start: Int64(start),
            end: Int64(end),
            completionHandler: completionHandler
        )
    }

    private func topArtists(start: Int64, end: Int64,
                            completionHandler: @escaping PagerCompletionHandler,
                            firstLoad: Bool = false) {
        api.topArtistsPerWeek(from: start, to: end) { [weak self] in
            guard let self = self else { return }
            do {
                let items = try $0.get()
                // If this is the initial load and there's no data available
                // then we should update the UI
                guard !firstLoad || !items.isEmpty else {
                    completionHandler(.success(0))
                    return
                }
                // If the page size is greater than 1 then we've retrieved more
                // than just the current week, so there could be more data in
                // the next page. Therefore this isn't just a refresh of the
                // current week
                if items.count > 1 { self.refreshingCurrentWeek = false }
                try self.dao.batchUpsert(items: items)
                completionHandler(.success(items.count))
            } catch {
                // If we failed to refresh then we should try again next time
                self.refreshingCurrentWeek = false
                completionHandler(.failure(error))
            }
        }
    }
}

// Note: All extensions here will convert dates into GMT timezones even if
// the dates were in another timezone. This is a specific requirement of
// PlayHistoryPager to ensure that database queries are working correctly
private extension Date {
    /// Calendar value with timezone fixed to GMT
    private static var gregorian: Calendar = {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "GMT")!
        return gregorian
    }()

    /// Get the date on Monday of self's week
    var startOfWeek: Date {
        let sunday = Date.gregorian.date(
            from: Date.gregorian.dateComponents(
                [.yearForWeekOfYear, .weekOfYear, .timeZone],
                from: self
            )
        )!
        // If we're already on a sunday then we want to go back to the previous
        // Monday
        guard dayOfYear != sunday.dayOfYear else {
            // Subtract 6 days
            return Date.gregorian.date(byAdding: .day, value: -6, to: sunday)!
        }
        return Date.gregorian.date(byAdding: .day, value: 1, to: sunday)!
    }

    func plusWeeks(_ increment: Int) -> Date {
        return Date.gregorian.date(
            byAdding: .weekOfYear,
            value: increment,
            to: self
        )!
    }

    func minusWeeks(_ decrement: Int) -> Date {
        return plusWeeks(-decrement)
    }

    /// Get midnight of self
    var startOfDay: Date {
        return Date.gregorian.startOfDay(for: self)
    }
}
