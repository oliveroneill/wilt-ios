enum ArtistSearchState {
    case loading
    case loaded([ArtistViewModel])
    case error(String)
}

/// View model for displaying search results for Spotify artists
final class ArtistSearchViewModel {
    private let dao: ListenLaterDao
    private let api: SearchAPI
    private let backgroundQueue = DispatchQueue(
        label: "com.oliveroneill.wilt.ArtistSearchViewModel.backgroundQueue"
    )
    weak var delegate: ArtistSearchViewModelDelegate?
    /// Keep track of the current search so that we can cancel one if the user asks for another query
    private var currentSearch: Cancellable?
    private var currentState = ArtistSearchState.loaded([]) {
        didSet {
            onStateChange?(currentState)
        }
    }
    var onStateChange: ((ArtistSearchState) -> Void)?
    /// Used to keep track of what's waiting to be run based on the debounce of the search
    private var currentWorkItemForDebouncing: DispatchWorkItem?

    /// Create a view model for the search results controller
    ///
    /// - Parameters:
    ///   - dao: Where the choice will be inserted
    ///   - api: The api to be searched upon
    init(dao: ListenLaterDao, api: SearchAPI) {
        self.dao = dao
        self.api = api
    }

    func onViewAppeared() {
        onStateChange?(currentState)
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            // We ignore this error since we can retry when the user searches
            // and display the error then
            self.api.prepare { _ in }
        }
    }

    func onItemPressed(artist: ArtistViewModel) {
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.dao.insert(item: artist.toListenLaterArtist())
                self.onSearchExit()
            } catch {
                let errorMessage = String(
                    format: "star_insert_error".localized,
                    artist.artistName
                )
                self.currentState = .error(errorMessage)
            }
        }
    }

    func onSearchExit() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.onSearchExit()
        }
    }

    func onSearchTextChanged(text: String) {
        debounce { [weak self] in
            guard let self = self else { return }
            self.search(text: text)
        }
    }

    private func search(text: String) {
        guard !text.isEmpty else { return }
        // Change state to loading
        currentState = .loading
        // Search the api in the background
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            self.currentSearch?.cancel()
            self.currentSearch = self.api.search(artistQuery: text) { [weak self] in
                guard let self = self else { return }
                self.currentSearch = nil
                // Check the response
                guard let results = try? $0.get() else {
                    self.currentState = .error("search_error".localized)
                    return
                }
                // Map the results to the view model
                let resultData = results.map {
                    ArtistViewModel(
                        artistName: $0.artistName,
                        imageURL: $0.imageURL,
                        externalURL: $0.externalURL
                    )
                }
                self.currentState = .loaded(resultData)
            }
        }
    }

    /// Debounce the current action and only send it if it's been 0.1 seconds since the last
    /// action
    /// - Parameter callback: The action to perform
    private func debounce(callback: @escaping (() -> Void)) {
        // Cancel whatever we were currently waiting for since this new search
        // is more up to date
        currentWorkItemForDebouncing?.cancel()
        let workItem = DispatchWorkItem(block: callback)
        // Wait 0.1 seconds before searching
        backgroundQueue.asyncAfter(deadline: .now() + 0.1, execute: workItem)
        currentWorkItemForDebouncing = workItem
    }
}

extension ArtistViewModel {
    func toListenLaterArtist() -> ListenLaterArtist {
        return ListenLaterArtist(
            name: artistName,
            externalURL: externalURL,
            imageURL: imageURL
        )
    }
}

/// Delegate for the `ArtistSearchViewModel` for events that occur during the
/// feed
protocol ArtistSearchViewModelDelegate: class {
    func onSearchExit()
    func loggedOut()
}
