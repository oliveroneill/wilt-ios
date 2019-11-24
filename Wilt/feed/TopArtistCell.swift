import Foundation
import SDWebImage

/// A single table view for the play history feed. See `FeedViewController`
final class TopArtistCell: UITableViewCell {
    static let reuseIdentifier = "topArtistCell"
    private lazy var roundCornerTransformer: SDImageTransformer = {
        return SDImagePipelineTransformer(
            transformers: [
                SDImageCroppingTransformer(
                    rect: CGRect(
                        origin: .zero,
                        // Fix the height and width since the images out of
                        // Spotify aren't consistent sizes
                        size: CGSize(width: 640, height: 640)
                    )
                ),
                SDImageRoundCornerTransformer(
                    // This will ensure that the image comes out as a circle
                    radius: CGFloat.greatestFiniteMagnitude,
                    corners: .allCorners,
                    borderWidth: 0,
                    borderColor: nil
                )
            ]
        )
    }()
    /// Set this when the view is being reused
    var viewModel: FeedItemViewModel? {
        didSet {
            artistLabel.text = viewModel?.artistName ?? ""
            playsLabel.text = viewModel?.playsText ?? ""
            dateLabel.text = viewModel?.dateText ?? ""
            if let imageURL = viewModel?.imageURL {
                artistImageView.sd_setImage(
                    with: imageURL,
                    placeholderImage: nil,
                    context: [.imageTransformer: roundCornerTransformer]
                )
            }
        }
    }
    private lazy var artistLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    private let playsLabel = UILabel(frame: .zero)
    private let dateLabel = UILabel(frame: .zero)
    // I know UITableViewCell has it's own imageView property but I didn't
    // want to have to unwrap it all the time
    private let artistImageView = UIImageView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Setup views
        contentView.addSubview(artistLabel)
        contentView.addSubview(playsLabel)
        contentView.addSubview(dateLabel)
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
                equalTo: playsLabel.topAnchor,
                constant: -8
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
                equalTo: artistImageView.trailingAnchor,
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
                equalTo: artistImageView.trailingAnchor,
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
