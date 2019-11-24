import UIKit

/// A single page of the walkthrough
final class OnboardingPage: UIViewController {
    private let text: String
    private let image: UIImage?
    private var label: UILabel!
    private var imageView: UIImageView!

    /// Initialise the page
    ///
    /// - Parameters:
    ///   - text: The subtitle text
    ///   - image: The image to display
    init(text: String, image: UIImage?) {
        self.text = text
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        setupLabel()
        setupImageView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabelAppearance()
        setupImageViewAppearance()
    }

    private func setupLabelAppearance() {
        label.numberOfLines = 0
        label.text = text
        label.font = UIFont.systemFont(ofSize: 24.0)
    }

    private func setupImageViewAppearance() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private func setupLabel() {
        label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -8
            ),
            label.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 8
            ),
            label.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -8
            ),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
    }

    private func setupImageView() {
        imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            imageView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            imageView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            imageView.bottomAnchor.constraint(
                equalTo: label.bottomAnchor,
                constant: -8
            ),
        ])
    }
}
