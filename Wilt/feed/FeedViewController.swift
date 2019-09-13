import Foundation

/// A controller for displaying the user's play history as a feed, with infinite
/// scrolling and caching implemented
class FeedViewController: UITableViewController {
    private let viewModel: FeedViewModel
    private lazy var customRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(
            string: "loading_txt".localized
        )
        refreshControl.addTarget(
            self,
            action: #selector(refresh),
            for: .valueChanged
        )
        return refreshControl
    }()

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        TopArtistCell.register(tableView: tableView)
        viewModel.onRowsUpdated = { [unowned self] in
            DispatchQueue.main.async { [unowned self] in
                self.tableView.reloadData()
            }
        }
        viewModel.onViewUpdate = { [unowned self] in
            self.onViewUpdate(state: $0)
        }
        refreshControl = customRefreshControl
        tableView.allowsSelection = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func refresh() {
        viewModel.refresh()
    }

    private func onViewUpdate(state: FeedViewState) {
        DispatchQueue.main.async { [unowned self] in
            switch state {
            case .displayingRows:
                self.tableView.hideLoadingFooter()
                self.refreshControl?.stopRefreshing()
            case .loadingAtTop:
                self.tableView.hideLoadingFooter()
                self.tableView.showRefreshHeader()
            case .loadingAtBottom:
                self.refreshControl?.stopRefreshing()
                self.tableView.showLoadingFooter()
            case .empty:
                // TODO: display message
                self.tableView.hideLoadingFooter()
                self.refreshControl?.stopRefreshing()
            case .errorAtBottom:
                // TODO: display message
                self.tableView.hideLoadingFooter()
                self.refreshControl?.stopRefreshing()
            case .errorAtTop:
                // TODO: display message
                self.tableView.hideLoadingFooter()
                self.refreshControl?.stopRefreshing()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.onViewAppeared()
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TopArtistCell.reuseIdentifier,
            for: indexPath
        ) as! TopArtistCell
        cell.viewModel = item
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.items.count - 1 {
            viewModel.onScrolledToBottom()
        } else if indexPath.row == 0 {
            viewModel.onScrolledToTop()
        }
    }
}

extension UITableView {
    private static let loadingFooterHeight: CGFloat = 50
    var isLoadingFooterShowing: Bool {
        return tableFooterView is UIActivityIndicatorView
    }

    func showLoadingFooter(){
        guard !isLoadingFooterShowing else {
            return
        }
        let footer = UIActivityIndicatorView(style: .gray)
        footer.frame.size.height = UITableView.loadingFooterHeight
        footer.startAnimating()
        tableFooterView = footer
    }

    func hideLoadingFooter(){
        guard isLoadingFooterShowing else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.contentOffset.y -= UITableView.loadingFooterHeight
        }, completion: { _ in
            self.tableFooterView = nil
        })
    }

    func showRefreshHeader() {
        // We won't animate the loading spinner if the user is already
        // scrolling
        refreshControl?.refresh(animate: !isDragging || !isDecelerating)
    }
}

extension UIRefreshControl {
    /// Refresh and swipe down to display the loading spinner
    ///
    /// - Parameter animate: Whether to swipe down or not
    func refresh(animate: Bool) {
        if animate, let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(
                CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height),
                animated: false
            )
        }
        if !isRefreshing {
            beginRefreshing()
        }
    }

    func stopRefreshing() {
        if isRefreshing {
            endRefreshing()
        }
    }
}
