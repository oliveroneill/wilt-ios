/// View model for a single cell in the list
struct ListenLaterItemViewModel: Equatable {
    let artistName: String
    let imageURL: URL
    let externalURL: URL
}

/// View model for displaying the user's list of artists they want to listen to
final class ListenLaterViewModel {
    private let dao: ListenLaterDao
    private let backgroundQueue = DispatchQueue(
        label: "com.oliveroneill.wilt.ListenLaterViewModel.backgroundQueue"
    )
    weak var delegate: ListenLaterViewModelDelegate?

    /// This is a specific state update when the rows of the list change. This
    /// needs to be modelled separately since it will reload the views and
    /// it would be ugly to have a state that does that
    var onRowsUpdated: (() -> Void)?
    /// The items that should be displayed on the feed as cells
    var items: [ListenLaterItemViewModel] {
        return dao.items.lazy.map {
            ListenLaterItemViewModel(
                artistName: $0.name,
                imageURL: $0.imageURL,
                externalURL: $0.externalURL
            )
        }
    }

    /// Create a view model for the listen later list
    ///
    /// - Parameters:
    ///   - dao: Where data will be stored and retrieved
    init(dao: ListenLaterDao) {
        self.dao = dao
        dao.onDataChange = { [weak self] in
            self?.onRowsUpdated?()
        }
    }

    func onRowTapped(rowIndex: Int) {
        delegate?.open(url: items[rowIndex].externalURL)
    }
}

/// Delegate for the `FeedViewModel` for events that occur during the
/// feed
protocol ListenLaterViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
}
