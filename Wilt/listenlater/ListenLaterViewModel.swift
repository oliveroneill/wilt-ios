/// View model for a single cell in the list
struct ListenLaterItemViewModel: Equatable {
    let artistName: String
    let imageURL: URL
    let externalURL: URL
}

/// View model for displaying the user's list of artists they want to listen to
/// TODO: These artists should really be stored on the server
final class ListenLaterViewModel {
    private let dao: ListenLaterDao
    private let backgroundQueue = DispatchQueue(
        label: "com.oliveroneill.wilt.ListenLaterViewModel.backgroundQueue"
    )
    weak var delegate: ListenLaterViewModelDelegate?

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
    }

    func onRowTapped(rowIndex: Int) {
        delegate?.open(url: items[rowIndex].externalURL)
    }

    /// Called when a row is indicated to be deleted by a user
    /// - Parameters:
    ///   - rowIndex: The index of the row
    ///   - onDeletionComplete: Called when the row deletion operation is complete, the boolean
    /// will indicate whether it failed or not. True means succeeded
    func onDeletePressed(rowIndex: Int, onDeletionComplete: @escaping ((Bool) -> Void)) {
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                onDeletionComplete(false)
                return
            }
            do {
                try self.dao.delete(
                    name: self.items[rowIndex].artistName
                )
                onDeletionComplete(true)
            } catch {
                // TODO: actually show the user the error
                onDeletionComplete(false)
            }
        }
    }
}

/// Delegate for the `FeedViewModel` for events that occur during the
/// feed
protocol ListenLaterViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
}
