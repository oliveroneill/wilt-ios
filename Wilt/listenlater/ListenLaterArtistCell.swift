import Foundation
import SDWebImage

/// A single table view cell for the listen later page. See `ListenLaterViewController`
final class ArtistTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ArtistTableViewCell"
    /// Set this when the view is being reused
    var viewModel: ArtistViewModel? {
        didSet {
            artistLabel.text = viewModel?.artistName ?? ""
            if let imageURL = viewModel?.imageURL {
                artistImageView.sd_setImage(
                    with: imageURL,
                    placeholderImage: nil,
                    context: [
                        .imageTransformer: SDImageTransformers.roundCornerTransformer
                    ]
                )
            }
        }
    }
    private lazy var artistLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    // I know UITableViewCell has it's own imageView property but I didn't
    // want to have to unwrap it all the time
    private let artistImageView = UIImageView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Setup views
        contentView.addSubview(artistLabel)
        contentView.addSubview(artistImageView)
        artistImageView.translatesAutoresizingMaskIntoConstraints = false
        artistImageView.contentMode = .scaleAspectFill
        NSLayoutConstraint.activate([
            artistImageView.topAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            artistImageView.bottomAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            artistImageView.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            artistImageView.trailingAnchor.constraint(
                equalTo: artistLabel.leadingAnchor,
                constant: -16
            ),
            artistImageView.widthAnchor.constraint(
                equalTo: artistImageView.heightAnchor
            ),
        ])
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            artistLabel.topAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            artistLabel.bottomAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.bottomAnchor,
                constant: -32
            ),
            artistLabel.leadingAnchor.constraint(
                equalTo: artistImageView.trailingAnchor,
                constant: 16
            ),
            artistLabel.trailingAnchor.constraint(
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
            ArtistTableViewCell.self,
            forCellReuseIdentifier: ArtistTableViewCell.reuseIdentifier
        )
    }
}
