import Foundation

/// A single table view for the play history feed. See `FeedViewController`
class TopArtistCell: UITableViewCell {
    static let reuseIdentifier = "topArtistCell"
    /// Set this when the view is being reused
    var viewModel: FeedItemViewModel? {
        didSet {
            artistLabel.text = viewModel?.artistName ?? ""
            playsLabel.text = viewModel?.playsText ?? ""
            dateLabel.text = viewModel?.dateText ?? ""
        }
    }
    private let artistLabel: UILabel
    private let playsLabel: UILabel
    private let dateLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        artistLabel = UILabel(frame: .zero)
        artistLabel.font = UIFont.boldSystemFont(ofSize: 16)
        playsLabel = UILabel(frame: .zero)
        dateLabel = UILabel(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Setup views
        contentView.addSubview(artistLabel)
        contentView.addSubview(playsLabel)
        contentView.addSubview(dateLabel)
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artistLabel.topAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            artistLabel.bottomAnchor.constraint(
                equalTo: playsLabel.topAnchor,
                constant: -8
            ),
            artistLabel.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            artistLabel.trailingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
        ])
        playsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playsLabel.topAnchor.constraint(
                equalTo: artistLabel.bottomAnchor,
                constant: 8
            ),
            playsLabel.bottomAnchor.constraint(
                equalTo: dateLabel.topAnchor,
                constant: -8
            ),
            playsLabel.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            playsLabel.trailingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
        ])
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(
                equalTo: playsLabel.bottomAnchor,
                constant: 8
            ),
            dateLabel.bottomAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            dateLabel.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            dateLabel.trailingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Register this class to be used with the specified table view
    ///
    /// - Parameter tableView: The tableview to register use with
    static func register(tableView: UITableView) {
        tableView.register(
            TopArtistCell.self,
            forCellReuseIdentifier: TopArtistCell.reuseIdentifier
        )
    }
}
