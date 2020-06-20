import UIKit

/// View controller for the profile screen. This will use a collection view
/// to display cards about the user
final class ProfileViewController: UIViewController {
    private let viewModel: ProfileViewModel
    /// The current state
    private var cards: [CardViewModelState]? {
        didSet {
            collectionView.reloadData()
        }
    }
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(
            top: 16, left: 16, bottom: 16, right: 16
        )
        return layout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: flowLayout
        )
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // Used for KIF testing
        collectionView.accessibilityIdentifier = "profile_collection_view"
        ProfileCardView.register(collectionView: collectionView)
        return collectionView
    }()

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 0
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: 0
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 0
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: 0
            ),
        ])
        viewModel.onViewUpdate = { [weak self] in
            self?.updateState(state: $0)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayoutSubviews() {
        // To handle resizing views for orientation change
        collectionView.reloadData()
    }

    func updateState(state: [CardViewModelState]) {
        DispatchQueue.main.async { [weak self] in
            self?.cards = state
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.onViewAppeared()
    }
}

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cards = cards else {
            fatalError("There's a cell but no cards")
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProfileCardView.reuseIdentifier,
            for: indexPath
        ) as! ProfileCardView
        // Setup the view
        cell.configure(state: cards[indexPath.row]) { [weak self] in
            self?.viewModel.onRetryButtonPressed(cardIndex: indexPath.row)
        }
        return cell
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.onCardTapped(cardIndex: indexPath.row)
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width - 32, height: 300)
    }
}
