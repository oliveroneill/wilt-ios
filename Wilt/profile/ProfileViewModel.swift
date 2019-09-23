import SwiftDate

/// Specification for cards to be requested and displayed
///
/// - topArtist: If it's a artist card
/// - topTrack: If it's a track card
enum ProfileCard {
    case topArtist(index: Int, timeRange: TimeRange)
    case topTrack(index: Int, timeRange: TimeRange)

    /// The readable string will be displayed to the user
    var readableString: String {
        switch (self) {
        case .topArtist(_, let timeRange):
            switch (timeRange) {
            case .longTerm:
                return "top_artist_long_term_text".localized
            case .mediumTerm:
                return "top_artist_medium_term_text".localized
            case .shortTerm:
                return "top_artist_short_term_text".localized
            }
        case .topTrack(_, let timeRange):
            switch (timeRange) {
            case .longTerm:
                return "top_track_long_term_text".localized
            case .mediumTerm:
                return "top_track_medium_term_text".localized
            case .shortTerm:
                return "top_track_short_term_text".localized
            }
        }
    }
}

/// The view state of a single card
///
/// - loading: Loading the details of the card
/// - loaded: The card is loaded
/// - error: Something went wrong
enum CardViewModelState: Equatable {
    case loading(tagTitle: String)
    case loaded(
        tagTitle: String,
        title: String,
        subtitleFirstLine: String,
        subtitleSecondLine: String,
        imageURL: URL,
        // TODO: this shouldn't really be in the view model but otherwise
        // it's annoying to store the models as well
        externalURL: URL
    )
    case error
}

/// View model for the profile screen
class ProfileViewModel {
    private let cards: [ProfileCard] = [
        .topArtist(index: 0, timeRange: .longTerm),
        .topTrack(index: 0, timeRange: .longTerm),
        .topArtist(index: 0, timeRange: .shortTerm),
        .topTrack(index: 0, timeRange: .shortTerm),
        .topArtist(index: 0, timeRange: .mediumTerm),
        .topTrack(index: 0, timeRange: .mediumTerm),
    ]
    private let api: ProfileAPI
    private let queue = DispatchQueue(label: "com.oliveroneill.wilt.ProfileViewModel.queue")
    private var cardStates: [CardViewModelState] {
        didSet {
            onViewUpdate?(cardStates)
        }
    }
    /// The view should set this value to receive state updates
    var onViewUpdate: (([CardViewModelState]) -> Void)?
    weak var delegate: ProfileViewModelDelegate?

    init(api: ProfileAPI) {
        self.api = api
        // Initial state will be loading
        cardStates = cards.map { .loading(tagTitle: $0.readableString) }
    }

    func onViewAppeared() {
        // When the view appears we'll load the cards
        cardStates = cards.map { .loading(tagTitle: $0.readableString) }
        queue.async { [unowned self] in
            // Make a request for each card
            self.cards.enumerated().forEach {
                let (cardIndex, card) = $0
                self.loadCard(card: card, cardIndex: cardIndex)
            }
        }
    }

    private func loadCard(card: ProfileCard, cardIndex: Int) {
        switch (card) {
        case .topArtist(let index, let timeRange):
            api.topArtist(timeRange: timeRange.description, index: index) { [unowned self] in
                do {
                    let artist = try $0.get()
                    self.cardStates[cardIndex] = artist.toViewModel(
                        tagTitle: card.readableString
                    )
                } catch {
                    print("topArtist error", error)
                    self.cardStates[cardIndex] = .error
                    guard (error as? WiltAPIError) != WiltAPIError.loggedOut else {
                        // Call delegate on main thread since it will do navigation
                        // things
                        DispatchQueue.main.async { [unowned self] in
                            self.delegate?.loggedOut()
                        }
                        return
                    }
                }
            }
        case .topTrack(let index, let timeRange):
            api.topTrack(timeRange: timeRange.description, index: index) { [unowned self] in
                do {
                    let track = try $0.get()
                    self.cardStates[cardIndex] = track.toViewModel(
                        tagTitle: card.readableString
                    )
                } catch {
                    print("topTrack error", error)
                    self.cardStates[cardIndex] = .error
                    guard (error as? WiltAPIError) != WiltAPIError.loggedOut else {
                        // Call delegate on main thread since it will do navigation
                        // things
                        DispatchQueue.main.async { [unowned self] in
                            self.delegate?.loggedOut()
                        }
                        return
                    }
                }
            }
        }
    }

    func onRetryButtonPressed(cardIndex: Int) {
        let card = cards[cardIndex]
        cardStates[cardIndex] = .loading(tagTitle: card.readableString)
        queue.async { [unowned self] in
            self.loadCard(card: card, cardIndex: cardIndex)
        }
    }

    func onCardTapped(cardIndex: Int) {
        let card = cardStates[cardIndex]
        guard case let .loaded(_, _, _, _, _, externalURL) = card else {
            return
        }
        delegate?.open(url: externalURL)
    }
}

extension TopTrackInfo {
    /// Convert the data into a view model
    func toViewModel(tagTitle: String) -> CardViewModelState {
        let lastPlayedText: String
        if let lastPlayed = lastPlayed {
            lastPlayedText = "Last listened to \(lastPlayed.relative)"
        } else {
            lastPlayedText = ""
        }
        let totalPlayText: String
        if let totalPlayTimeString = totalPlayTime.readableDuration {
            totalPlayText = "\(totalPlayTimeString) spent listening since joining Wilt"
        } else {
            totalPlayText = ""
        }
        return .loaded(
            tagTitle: tagTitle,
            title: name,
            subtitleFirstLine: totalPlayText,
            subtitleSecondLine: lastPlayedText,
            imageURL: imageURL,
            externalURL: externalURL
        )
    }
}

extension TopArtistInfo {
    /// Convert the data into a view model
    func toViewModel(tagTitle: String) -> CardViewModelState {
        let lastPlayedText: String
        if let lastPlayed = lastPlayed {
            lastPlayedText = "Last listened to \(lastPlayed.relative)"
        } else {
            lastPlayedText = ""
        }
        return .loaded(
            tagTitle: tagTitle,
            title: name,
            subtitleFirstLine: "\(count) plays since joining Wilt",
            subtitleSecondLine: lastPlayedText,
            imageURL: imageURL,
            externalURL: externalURL
        )
    }
}

extension TimeInterval {
    /// Convert self to a readable duration, eg. 2 days
    var readableDuration: String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        return formatter.string(from: self)
    }
}

extension Date {
    /// Convert self into a relative date from now, eg. 6 days ago
    var relative: String {
        return toRelative(
            style: RelativeFormatter.defaultStyle(),
            locale: Locales.english
        )
    }
}

protocol ProfileViewModelDelegate: class {
    func open(url: URL)
    func loggedOut()
}
