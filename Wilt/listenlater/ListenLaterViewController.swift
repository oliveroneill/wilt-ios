import UIKit

/// A controller for displaying a stored list of artist's that the user plans to listen to later
final class ListenLaterViewController: UITableViewController {
    private let viewModel: ListenLaterViewModel
    private lazy var emptyDataView: UIView = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 21)
        label.textAlignment = .center
        label.textColor = .gray
        label.text = "listen_later_empty_data_text".localized
        label.numberOfLines = 0
        return label
    }()

    init(viewModel: ListenLaterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.onRowsDeleted = { rows in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.deleteRows(
                    at: rows.map { IndexPath(row: $0, section: 0) },
                    with: .left
                )
                if self.viewModel.items.isEmpty {
                    self.tableView.backgroundView = self.emptyDataView
                }
            }
        }
        viewModel.onDeleteError = { message in
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
        ArtistTableViewCell.register(tableView: tableView)
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
        // Used for KIF testing
        tableView.accessibilityIdentifier = "listen_later_table_view"
    }

    override func viewDidAppear(_ animated: Bool) {
        if viewModel.items.isEmpty {
            tableView.backgroundView = self.emptyDataView
        } else {
            // We must delete the background view since there are cells
            // available
            tableView.backgroundView = nil
            tableView.reloadData()
            // Show hint for swipe action
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?
                .hintSwipeAction(swipeActionColor: .red)
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
            withIdentifier: ArtistTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! ArtistTableViewCell
        cell.viewModel = item
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.onRowTapped(rowIndex: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let title = "listen_later_undo_action_title".localized
        let action = UIContextualAction(style: .normal, title: title) {
            self.viewModel.onDeletePressed(rowIndex: indexPath.row)
            $2(true)
        }
        action.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
}
