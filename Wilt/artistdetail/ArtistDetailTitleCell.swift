import Foundation
import SDWebImage
import SwiftIcons

/// The table view cell for displaying the artist name and photo.
final class ArtistDetailTitleCell: UITableViewCell {
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
    /// The view data that should be displayed in the cell. Once this is set the view will update itself
    var viewModel: ArtistInfo? {
        didSet {
            artistLabel.text = viewModel?.name ?? ""
            if let viewModel = viewModel {
                artistImageView.sd_setImage(
                    with: viewModel.imageURL,
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
    // I know UITableViewCell has it's own imageView property but I didn't
    // want to have to unwrap it all the time
    private let artistImageView = UIImageView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)
        isUserInteractionEnabled = false
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
