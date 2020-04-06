import Foundation

/// A controller for displaying the user's play history as a feed, with infinite
/// scrolling and caching implemented
final class FeedViewController: UITableViewController {
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
        label.text = "empty_data_text".localized
        label.numberOfLines = 0
        return label
    }()
    private var errorButton: UIButton {
        let button = UIButton(frame: .zero)
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
        let button = errorButton
        // Used for KIF testing
        button.accessibilityLabel = "feed_error_footer_text".localized
        return button
    }()
    private lazy var errorHeaderView: UIButton = {
        let button = errorButton
        // Used for KIF testing
        button.accessibilityLabel = "feed_error_header_text".localized
        return button
    }()

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        TopArtistCell.register(tableView: tableView)
        viewModel.onRowsUpdated = {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
        viewModel.onStarsUpdated = {
            // To avoid jank from the swipe animation being cut short we
            // need to wait a second. This seems like a hack but the alternative
            // is using didEndEditing to infer that the animation finished,
            // however I found this to be too slow to seem responsive :(
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
        viewModel.onStarError = { message in
            DispatchQueue.main.async { [weak self] in
                let alert = UIAlertController(
                    title: "Uh oh!",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(
                    UIAlertAction(title: "OK", style: .default) { _ in
                        alert.dismiss(animated: true)
                    }
                )
                self?.present(alert, animated: true, completion: nil)
            }
        }
        viewModel.onViewUpdate = { [weak self] in
            self?.onViewUpdate(state: $0)
        }
        refreshControl = customRefreshControl
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
        // Used for KIF testing
        tableView.accessibilityIdentifier = "feed_table_view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func refresh() {
        viewModel.refresh()
    }

    private func onViewUpdate(state: FeedViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
                self.tableView.backgroundView = self.emptyDataView
            case .errorAtBottom:
                self.tableView.showErrorFooter(
                    retryButton: self.errorFooterView
                )
                self.errorFooterView.addTarget(
                    self,
                    action: #selector(self.retryLoadFromBottom),
                    for: .touchUpInside
                )
            case .errorAtTop:
                self.tableView.showErrorHeader(
                    retryButton: self.errorHeaderView
                )
                self.errorHeaderView.addTarget(
                    self,
                    action: #selector(self.retryLoadFromTop),
                    for: .touchUpInside
                )
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        viewModel.onViewDisappeared()
    }

    @objc func retryLoadFromBottom() {
        viewModel.onRetryFooterPressed()
    }

    @objc func retryLoadFromTop() {
        viewModel.onRetryHeaderPressed()
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.onViewAppeared()
        // If there's at least one element then we should indicate
        // that there's a swipe action available
        if !viewModel.items.isEmpty {
            let first = IndexPath(row: 0, section: 0)
            tableView.cellForRow(at: first)?.hintSwipeAction(
                swipeActionColor: swipeColor(for: first)
            )
        }
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
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.onRowTapped(rowIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let isStarred = viewModel.items[indexPath.row].isStarred
        let title = isStarred ? "listen_later_undo_action_title".localized :
            "listen_later_action_title".localized

        let action = UIContextualAction(style: .normal, title: title) {
            if isStarred {
                self.viewModel.onRowUnstarred(rowIndex: indexPath.row)
            } else {
                self.viewModel.onRowStarred(rowIndex: indexPath.row)
            }
            $2(true)
        }
        action.backgroundColor = swipeColor(for: indexPath)
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }

    func swipeColor(for indexPath: IndexPath) -> UIColor {
        let isStarred = viewModel.items[indexPath.row].isStarred
        let lightBlue = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        return isStarred ? .gray : lightBlue
    }
}

extension UITableView {
    private static let loadingFooterHeight: CGFloat = 50
    var isLoadingFooterShowing: Bool {
        return tableFooterView is UIActivityIndicatorView
    }
    var isErrorFooterShowing: Bool {
        return tableFooterView is UIButton
    }
    var isErrorHeaderShowing: Bool {
        return tableHeaderView != nil
    }

    func showErrorFooter(retryButton: UIButton) {
        retryButton.frame.size.height = UITableView.loadingFooterHeight
        tableFooterView = retryButton
        // Change offset to show footer
        setContentOffset(
            CGPoint(x: 0, y: contentOffset.y + UITableView.loadingFooterHeight),
            animated: !isDragging || !isDecelerating
        )
    }

    func hideErrorFooter() {
        guard isErrorFooterShowing else {
            return
        }
        // This will hide the cell dividers when there's no data
        tableFooterView = UIView(frame: .zero)
    }

    func showErrorHeader(retryButton: UIButton) {
        retryButton.frame.size.height = UITableView.loadingFooterHeight
        tableHeaderView = retryButton
    }

    func hideErrorHeader() {
        guard isErrorHeaderShowing else {
            return
        }
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
        // This will hide the cell dividers when there's no data
        tableFooterView = UIView(frame: .zero)
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
