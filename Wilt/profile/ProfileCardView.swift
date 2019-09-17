import MaterialComponents.MaterialCards
import MaterialComponents.MaterialChips
import Shimmer
import SDWebImage

/// A card view for the profile tab
class ProfileCardView: MDCCardCollectionCell {
    static let reuseIdentifier = "profileCell"

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .lightGray
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitle1Label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .lightGray
        return label
    }()

    private lazy var subtitle2Label: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .lightGray
        return label
    }()

    private lazy var shimmer: FBShimmeringView = {
        let view = FBShimmeringView(frame: .zero)
        view.isShimmering = true
        view.shimmeringSpeed = 500
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var chip: MDCChipView = {
        let chip = MDCChipView()
        chip.sizeToFit()
        chip.translatesAutoresizingMaskIntoConstraints = false
        return chip
    }()

    /// Everything will live in this. Only necessary for the shimmer
    private lazy var rootView: UIView = {
        let root = UIView(frame: .zero)
        root.addSubview(imageView)
        root.addSubview(titleLabel)
        root.addSubview(subtitle1Label)
        root.addSubview(subtitle2Label)
        root.addSubview(chip)
        return root
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        shimmer.contentView = rootView
        addSubview(shimmer)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configure this view to show the specified view model
    ///
    /// - Parameter state: The data to display
    func configure(state: CardViewModelState) {
        cornerRadius = 8
        setShadowElevation(.cardPickedUp, for: .selected)
        setShadowColor(.black, for: .highlighted)
        switch (state) {
        case .loading(let tagTitle):
            shimmer.isShimmering = true
            titleLabel.backgroundColor = .lightGray
            subtitle2Label.backgroundColor = .lightGray
            subtitle1Label.backgroundColor = .lightGray
            chip.titleLabel.text = tagTitle
            chip.sizeToFit()
        case .loaded(let tagTitle, let title, let subtitle1, let subtitle2,
                     let imageURL):
            shimmer.isShimmering = false
            titleLabel.backgroundColor = .white
            subtitle2Label.backgroundColor = .white
            subtitle1Label.backgroundColor = .white
            chip.titleLabel.text = tagTitle
            chip.sizeToFit()
            titleLabel.text = title
            subtitle1Label.text = subtitle1
            subtitle2Label.text = subtitle2
            imageView.sd_setImage(with: imageURL)
        case .error:
            // TODO
            break
        }
    }

    static func register(collectionView: UICollectionView) {
        collectionView.register(
            ProfileCardView.self,
            forCellWithReuseIdentifier: reuseIdentifier
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 0
            ),
            shimmer.heightAnchor.constraint(
                equalToConstant: frame.size.height
            ),
            shimmer.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 0
            ),
            shimmer.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: 0
            ),
        ])
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 0
            ),
            imageView.heightAnchor.constraint(
                equalToConstant: frame.size.height * 0.6
            ),
            imageView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 0
            ),
            imageView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: 0
            ),
        ])
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: 8
            ),
            titleLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor,
                constant: -8
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 8
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -8
            ),
            titleLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        NSLayoutConstraint.activate([
            subtitle1Label.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 8
            ),
            subtitle1Label.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor,
                constant: -8
            ),
            subtitle1Label.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 8
            ),
            subtitle1Label.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -8
            ),
            subtitle1Label.heightAnchor.constraint(equalToConstant: 20)
        ])
        NSLayoutConstraint.activate([
            subtitle2Label.topAnchor.constraint(
                equalTo: subtitle1Label.bottomAnchor,
                constant: 8
            ),
            subtitle2Label.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor,
                constant: -8
            ),
            subtitle2Label.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: 8
            ),
            subtitle2Label.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -8
            ),
            subtitle2Label.heightAnchor.constraint(equalToConstant: 20)
        ])
        NSLayoutConstraint.activate([
            chip.topAnchor.constraint(
                equalTo: imageView.topAnchor,
                constant: 8
            ),
            chip.leadingAnchor.constraint(
                equalTo: imageView.leadingAnchor,
                constant: 8
            ),
            chip.widthAnchor.constraint(greaterThanOrEqualToConstant: 10),
        ])
    }
}
