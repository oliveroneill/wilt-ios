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
    private lazy var emptyDataView: UIView = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 21)
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "empty_data_text".localized
        label.numberOfLines = 0
        return label
    }()
    private var errorView: UIButton {
        let button = UIButton(frame: .zero)
        // Used for KIF testing
        button.accessibilityLabel = "feed_error_button"
        button.titleLabel?.textColor = .white
        button.setTitle("feed_error_text".localized, for: .normal)
        let lightRed = UIColor(
            hue: 0,
            saturation: 0.67,
            brightness: 1,
            alpha: 1
        )
        let darkRed = UIColor(
            hue: 0,
            saturation: 0.67,
            brightness: 0.8,
            alpha: 1
        )
        button.setBackgroundColor(lightRed, for: .normal)
        button.setBackgroundColor(darkRed, for: .highlighted)
        return button
    }
    private lazy var errorFooterView: UIButton = {
        return errorView
    }()
    private lazy var errorHeaderView: UIButton = {
        return errorView
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
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func refresh() {
        viewModel.refresh()
    }

    private func onViewUpdate(state: FeedViewState) {
        DispatchQueue.main.async { [unowned self] in
            self.tableView.hideLoadingFooter()
            self.refreshControl?.stopRefreshing()
            self.tableView.backgroundView = nil
            self.tableView.hideErrorHeader()
            self.tableView.hideErrorFooter()
            switch state {
            case .displayingRows:
                break
            case .loadingAtTop:
                self.tableView.showRefreshHeader()
            case .loadingAtBottom:
                self.tableView.showLoadingFooter()
            case .empty:
                // This will hide the cell dividers when there's no data
                self.tableView.tableFooterView = UIView(frame: .zero)
                self.tableView.backgroundView = self.emptyDataView
            case .errorAtBottom:
                self.tableView.showErrorFooter(view: self.errorFooterView)
                self.errorFooterView.addTarget(
                    self,
                    action: #selector(self.retryLoadFromBottom),
                    for: .touchUpInside
                )
            case .errorAtTop:
                self.tableView.showErrorHeader(view: self.errorHeaderView)
                self.errorHeaderView.addTarget(
                    self,
                    action: #selector(self.retryLoadFromTop),
                    for: .touchUpInside
                )
            }
        }
    }

    @objc func retryLoadFromBottom() {
        viewModel.onScrolledToBottom()
    }

    @objc func retryLoadFromTop() {
        viewModel.onScrolledToTop()
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
        if indexPath.row == viewModel.items.count - 1 &&
            !tableView.isErrorFooterShowing {
            viewModel.onScrolledToBottom()
        } else if indexPath.row == 0 && !tableView.isErrorHeaderShowing {
            viewModel.onScrolledToTop()
        }
    }
}

extension UITableView {
    private static let loadingFooterHeight: CGFloat = 50
    var isLoadingFooterShowing: Bool {
        return tableFooterView is UIActivityIndicatorView
    }
    var isErrorFooterShowing: Bool {
        return !isLoadingFooterShowing && tableFooterView != nil
    }
    var isErrorHeaderShowing: Bool {
        return tableFooterView != nil
    }

    func showErrorFooter(view: UIView) {
        view.frame.size.height = UITableView.loadingFooterHeight
        tableFooterView = view
        // Change offset to show footer
        setContentOffset(
            CGPoint(x: 0, y: contentOffset.y + UITableView.loadingFooterHeight),
            animated: !isDragging || !isDecelerating
        )
    }

    func hideErrorFooter() {
        tableFooterView = nil
    }

    func showErrorHeader(view: UIView) {
        view.frame.size.height = UITableView.loadingFooterHeight
        tableHeaderView = view
    }

    func hideErrorHeader() {
        tableHeaderView = nil
    }

    func showLoadingFooter(){
        guard !isLoadingFooterShowing else {
            return
        }
        let footer = UIActivityIndicatorView(style: .gray)
        footer.frame.size.height = UITableView.loadingFooterHeight
        footer.startAnimating()
        tableFooterView = footer
        // Change offset to show footer
        setContentOffset(
            CGPoint(x: 0, y: contentOffset.y + UITableView.loadingFooterHeight),
            animated: !isDragging || !isDecelerating
        )
    }

    func hideLoadingFooter(){
        guard isLoadingFooterShowing else {
            return
        }
        self.tableFooterView = nil
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
