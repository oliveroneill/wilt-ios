import Foundation

/// A controller for displaying the user's play history as a feed, with infinite
/// scrolling and caching implemented
final class HistoryViewController: UITableViewController {
    private let viewModel: HistoryViewModel
    private lazy var customRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(
            string: "track_history_loading_txt".localized
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

    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        TrackHistoryCell.register(tableView: tableView)
        viewModel.onRowsUpdated = {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
        viewModel.onViewUpdate = { [weak self] in
            self?.onViewUpdate(state: $0)
        }
        refreshControl = customRefreshControl
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
        // Used for KIF testing
        tableView.accessibilityIdentifier = "history_table_view"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func refresh() {
        viewModel.refresh()
    }

    private func onViewUpdate(state: HistoryViewState) {
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
            withIdentifier: TrackHistoryCell.reuseIdentifier,
            for: indexPath
        ) as! TrackHistoryCell
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
}
