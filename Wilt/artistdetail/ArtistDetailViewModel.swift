import Foundation

/// Set of artist info available when intialising detail screen
struct ArtistInfo: Equatable {
    let name: String
    let imageURL: URL
    let externalURL: URL
}

/// The view data for a single period of activity
struct ActivityPeriodViewData: Equatable {
    let dateText: String
    let numberOfPlays: Int
}

/// States of the view model
enum ArtistDetailViewModelState: Equatable {
    case loading(artist: ArtistInfo)
    case loaded(
        artist: ArtistInfo,
        activity: [ActivityPeriodViewData]
    )
    case error(errorMessage: String)
}

/// The view model for the artist detail screen
class ArtistDetailViewModel {
    private let artist: ArtistInfo
    private let api: ArtistActivityAPI
    private let queue = DispatchQueue(
        label: "com.oliveroneill.wilt.ArtistDetailViewModel.queue"
    )
    private var state: ArtistDetailViewModelState? {
        didSet {
            guard let state = state else { return }
            onViewUpdate?(state)
        }
    }
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    weak var delegate: ArtistDetailViewModelDelegate?
    /// The view should set this value to receive state updates
    var onViewUpdate: ((ArtistDetailViewModelState) -> Void)?

    init(artist: ArtistInfo, api: ArtistActivityAPI) {
        self.artist = artist
        self.api = api
    }

    func onViewLoaded() {
        /// Don't update the state if we've already loaded the view
        guard state == nil else {
            return
        }
        state = .loading(artist: artist)
        queue.async { [weak self] in
            guard let self = self else { return }
            let artistName = self.artist.name
            self.api.getArtistActivity(artistName: artistName) { [weak self] in
                self?.updateState(result: $0)
            }
        }
    }

    private func updateState(result: Result<[ArtistActivity], Error>) {
        switch result {
        case .success(let activity):
            let activityData = activity.map {
                ActivityPeriodViewData(
                    dateText: self.dateFormatter.string(from: $0.date),
                    numberOfPlays: $0.numberOfPlays
                )
            }
            // Show message if there's no data to show
            guard activityData.count > 0 else {
                self.state = .error(
                    errorMessage: "artist_detail_empty_data_message".localized
                )
                return
            }
            self.state = .loaded(artist: self.artist, activity: activityData)
        case .failure(let error):
            guard (error as? WiltAPIError) != WiltAPIError.loggedOut else {
                // Call delegate on main thread since it will do navigation
                // things
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.loggedOut()
                }
                return
            }
            print(error)
            self.state = .error(
                errorMessage: "artist_detail_error_message".localized
            )
        }
    }

    func openCellTapped() {
        delegate?.open(url: artist.externalURL)
    }

    func onDoneButtonTapped() {
        delegate?.close()
    }
}

/// Delegate for the `ArtistDetailViewModel` for events that occur on this screen
protocol ArtistDetailViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
    func close()
}
