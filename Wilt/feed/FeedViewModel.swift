/// The state that the feed view can be in
///
/// - displayingRows: Displaying play history content
/// - loadingAtTop: Loading spinner at top. It can show content at the same time
/// - loadingAtBottom: Loading spinner at the bottom, below existing content
/// - errorAtTop: Show an error at the top of screen
/// - errorAtBottom: Show an error at bottom top of screen
/// - empty: No rows available
enum FeedViewState {
    case displayingRows
    case loadingAtTop
    case loadingAtBottom
    case errorAtTop
    case errorAtBottom
    case empty
}

/// View model for a single cell in the play history feed
struct FeedItemViewModel: Equatable {
    let artistName: String
    let playsText: String
    let dateText: String
    let imageURL: URL
    let externalURL: URL
}

/// View model for displaying the user's music playing history in a feed
final class FeedViewModel {
    private let dao: PlayHistoryDao
    private let pager: PlayHistoryPager
    private let backgroundQueue = DispatchQueue(
        label: "com.oliveroneill.wilt.FeedViewModel.backgroundQueue"
    )
    /// Keep track of the state to avoid transitioning to the same state twice
    private var state: FeedViewState?
    weak var delegate: FeedViewModelDelegate?

    /// The view should set this value to receive state updates
    var onViewUpdate: ((FeedViewState) -> Void)?
    /// This is a specific state update when the rows of the feed change. This
    /// needs to be modelled separately since it will reload the views and
    /// it would be ugly to have a state that does that
    var onRowsUpdated: (() -> Void)?
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    /// The items that should be displayed on the feed as cells
    var items: [FeedItemViewModel] {
        return dao.items.lazy.map {
            FeedItemViewModel(
                artistName: $0.topArtist,
                playsText: "\($0.count) plays",
                dateText: "\(dateFormatter.string(from: $0.date))",
                imageURL: $0.imageURL,
                externalURL: $0.externalURL
            )
        }
    }

    /// Create a view model for the play history feed
    ///
    /// - Parameters:
    ///   - dao: Where data will be cached and retrieved
    ///   - api: Used for making network calls when the cache is out of date
    init(dao: PlayHistoryDao, api: WiltAPI) {
        self.dao = dao
        // This pager will be used to retrieve data in pages at a time and
        // inserting them into the cache
        pager = PlayHistoryPager(
            api: api,
            dao: dao,
            pageSize: 10
        )
        dao.onDataChange = { [weak self] in
            self?.onRowsUpdated?()
        }
    }

    private func updateState(state: FeedViewState) {
        self.state = state
        onViewUpdate?(state)
    }

    func onViewAppeared() {
        guard state != .loadingAtTop else {
            return
        }
        updateState(state: .loadingAtTop)
        loadLaterPage()
    }

    func refresh() {
        guard state != .loadingAtTop else {
            return
        }
        updateState(state: .loadingAtTop)
        loadLaterPage()
    }

    private func handleInsertResult(upsertCountResult: Result<Int, Error>,
                                    isItemsEmpty: Bool = false,
                                    onErrorState: FeedViewState = .errorAtTop) {
        do {
            let upsertCount = try upsertCountResult.get()
            guard !isItemsEmpty || upsertCount > 0 else {
                updateState(state: .empty)
                return
            }
            updateState(state: .displayingRows)
        } catch {
            guard (error as? WiltAPIError) != WiltAPIError.loggedOut else {
                // Call delegate on main thread since it will do navigation
                // things
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.loggedOut()
                }
                return
            }
            print("insert failed:", error)
            updateState(state: onErrorState)
        }
    }

    func onScrolledToBottom() {
        guard state != .loadingAtBottom else {
            return
        }
        updateState(state: .loadingAtBottom)
        loadEarlierPage()
    }

    func onRetryFooterPressed() {
        onScrolledToBottom()
    }

    func onRetryHeaderPressed() {
        guard state != .loadingAtTop else {
            return
        }
        updateState(state: .loadingAtTop)
        loadLaterPage()
    }

    func onViewDisappeared() {
        guard state == .loadingAtTop || state == .loadingAtBottom else {
            return
        }
        // If we were loading something then we need to stop the refresh
        // control otherwise it gets stuck. displayingRows will fix this and
        // when the view appears again we'll change the state as needed
        // See https://stackoverflow.com/questions/24341192/uirefreshcontrol-stuck-after-switching-tabs-in-uitabbarcontroller
        // TODO: this is a view-specific quirk so I'm not sure how this should
        // work
        updateState(state: .displayingRows)
    }

    func onRowTapped(rowIndex: Int) {
        delegate?.open(url: items[rowIndex].externalURL)
    }

    private func loadEarlierPage() {
        let earliestItem = dao.items.last
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            guard let earliestItem = earliestItem else {
                self.pager.onZeroItemsLoaded { [weak self] in
                    self?.handleInsertResult(
                        upsertCountResult: $0,
                        isItemsEmpty: true
                    )
                }
                return
            }
            self.pager.loadEarlierPage(earliestItem: earliestItem) { [weak self] in
                self?.handleInsertResult(
                    upsertCountResult: $0,
                    onErrorState: .errorAtBottom
                )
            }
        }
    }

    private func loadLaterPage() {
        let latestItem = dao.items.first
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            guard let latestItem = latestItem else {
                self.pager.onZeroItemsLoaded { [weak self] in
                    self?.handleInsertResult(
                        upsertCountResult: $0,
                        isItemsEmpty: true
                    )
                }
                return
            }
            self.pager.loadLaterPage(latestItem: latestItem) { [weak self] in
                self?.handleInsertResult(upsertCountResult: $0)
            }
        }
    }
}

/// Delegate for the `FeedViewModel` for events that occur during the
/// feed
protocol FeedViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
}
