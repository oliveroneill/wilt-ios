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

    private lazy var errorLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "profile_card_error_text".localized
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(frame: .zero)
        // Used for KIF testing
        button.accessibilityLabel = "profile_retry_button"
        button.setTitle("profile_card_retry_text".localized, for: .normal)
        button.titleLabel?.textColor = .white
        let darkBlue = UIColor(red: 0, green: 0.41, blue: 0.89, alpha: 1)
        button.setBackgroundColor(tintColor, for: .normal)
        button.setBackgroundColor(darkBlue, for: .highlighted)
        button.layer.cornerRadius = 4
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    /// Everything will live in this. Only necessary for the shimmer
    private lazy var rootView: UIView = {
        let root = UIView(frame: .zero)
        root.addSubview(imageView)
        root.addSubview(titleLabel)
        root.addSubview(subtitle1Label)
        root.addSubview(subtitle2Label)
        root.addSubview(chip)
        root.addSubview(errorLabel)
        root.addSubview(retryButton)
        return root
    }()

    var onRetryPressed: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        shimmer.contentView = rootView
        addSubview(shimmer)
        setupConstraints()
        cornerRadius = 8
        setShadowElevation(.cardPickedUp, for: .selected)
        setShadowColor(.black, for: .highlighted)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        resetViewsToLoadingState()
    }

    private func resetViewsToLoadingState() {
        shimmer.isShimmering = true
        titleLabel.backgroundColor = .lightGray
        subtitle2Label.backgroundColor = .lightGray
        subtitle1Label.backgroundColor = .lightGray
        imageView.backgroundColor = .lightGray
        imageView.image = nil
        titleLabel.text = ""
        subtitle1Label.text = ""
        subtitle2Label.text = ""
        chip.titleLabel.text = ""
    }

    private func setupSuccessfulView() {
        // Show views as needed
        titleLabel.isHidden = false
        subtitle1Label.isHidden = false
        subtitle2Label.isHidden = false
        chip.isHidden = false
        imageView.isHidden = false
        // Hide error views
        errorLabel.isHidden = true
        retryButton.isHidden = true
    }

    /// Configure this view to show the specified view model
    ///
    /// - Parameter state: The data to display
    func configure(state: CardViewModelState,
                   onRetryPressed: @escaping (() -> Void)) {
        self.onRetryPressed = onRetryPressed
        switch (state) {
        case .loading(let tagTitle):
            setupSuccessfulView()
            resetViewsToLoadingState()
            chip.titleLabel.text = tagTitle
            chip.sizeToFit()
        case .loaded(let tagTitle, let title, let subtitle1, let subtitle2,
                     let imageURL):
            shimmer.isShimmering = false
            setupSuccessfulView()
            // Update views
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
            shimmer.isShimmering = false
            titleLabel.isHidden = true
            subtitle1Label.isHidden = true
            subtitle2Label.isHidden = true
            chip.isHidden = true
            imageView.isHidden = true
            errorLabel.isHidden = false
            retryButton.isHidden = false
            retryButton.addTarget(
                self,
                action: #selector(retryPressed),
                for: .touchUpInside
            )
        }
    }

    @objc private func retryPressed() {
        onRetryPressed?()
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
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 0
            ),
            shimmer.heightAnchor.constraint(
                equalToConstant: frame.size.height
            ),
            shimmer.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 0
            ),
            shimmer.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: 0
            ),
        ])
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 0
            ),
            imageView.heightAnchor.constraint(
                equalToConstant: frame.size.height * 0.6
            ),
            imageView.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 0
            ),
            imageView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: 0
            ),
        ])
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: imageView.bottomAnchor,
                constant: 8
            ),
            titleLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
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
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
            subtitle1Label.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            subtitle1Label.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
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
                lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -8
            ),
            subtitle2Label.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            subtitle2Label.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
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
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorLabel.centerYAnchor.constraint(
                equalTo: safeAreaLayoutGuide.centerYAnchor,
                constant: -40
            ),
            errorLabel.heightAnchor.constraint(equalToConstant: 20),
            errorLabel.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            errorLabel.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
        ])
        NSLayoutConstraint.activate([
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.topAnchor.constraint(
                equalTo: errorLabel.bottomAnchor,
                constant: 8
            ),
            retryButton.heightAnchor.constraint(equalToConstant: 40),
            retryButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            retryButton.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
        ])
    }
}
