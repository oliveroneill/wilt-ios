import Foundation

/// A controller for displaying a stored list of artist's that the user plans to listen to later
final class ListenLaterViewController: UITableViewController {
    private let viewModel: ListenLaterViewModel
    private lazy var emptyDataView: UIView = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 21)
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "listen_later_empty_data_text".localized
        label.numberOfLines = 0
        return label
    }()

    init(viewModel: ListenLaterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        ListenLaterArtistCell.register(tableView: tableView)
        viewModel.onRowsUpdated = {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
                if self.viewModel.items.isEmpty {
                    self.tableView.backgroundView = self.emptyDataView
                }
            }
        }
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
        // Used for KIF testing
        tableView.accessibilityIdentifier = "listen_later_table_view"
    }

    override func viewDidAppear(_ animated: Bool) {
        if viewModel.items.isEmpty {
            tableView.backgroundView = self.emptyDataView
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            withIdentifier: ListenLaterArtistCell.reuseIdentifier,
            for: indexPath
        ) as! ListenLaterArtistCell
        cell.viewModel = item
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.onRowTapped(rowIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
