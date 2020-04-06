/// View model for displaying the user's list of artists they want to listen to
/// TODO: These artists should really be stored on the server
final class ListenLaterViewModel {
    private let dao: ListenLaterDao
    private let backgroundQueue = DispatchQueue(
        label: "com.oliveroneill.wilt.ListenLaterViewModel.backgroundQueue"
    )
    /// Triggered when rows are deleted. The argument to this closure is a list of indexes
    var onRowsDeleted: (([Int]) -> Void)?
    var onDeleteError: ((String) -> Void)?
    weak var delegate: ListenLaterViewModelDelegate?

    /// The items that should be displayed on the feed as cells
    var items: [ArtistViewModel] {
        return dao.items.lazy.map {
            ArtistViewModel(
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
    func onDeletePressed(rowIndex: Int) {
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.dao.delete(
                    name: self.items[rowIndex].artistName
                )
                self.onRowsDeleted?([rowIndex])
            } catch {
                self.onDeleteError?(
                    String(
                        format: "star_insert_error".localized,
                        self.items[rowIndex].artistName
                    )
                )
            }
        }
    }
}

/// Delegate for the `ListenLaterViewModel` for events that occur during the
/// feed
protocol ListenLaterViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
}
