import Foundation

class ArtistResultsTableViewController: UITableViewController {
    private let viewModel: ArtistSearchViewModel
    private var results: [ArtistViewModel]?
    /// Called when the view is loading or not. The boolean will be true if loading and false if not
    var onLoadingStateChanged: ((Bool) -> Void)?

    init(viewModel: ArtistSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.onStateChange = { state in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch (state) {
                case .loading:
                    self.onLoadingStateChanged?(true)
                case .loaded(let results):
                    self.onLoadingStateChanged?(false)
                    self.results = results
                    self.tableView.reloadData()
                case .error(let message):
                    self.onLoadingStateChanged?(false)
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
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        // This will hide the cell dividers when there's no data
        tableView.tableFooterView = UIView(frame: .zero)
        ArtistTableViewCell.register(tableView: tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        viewModel.onViewAppeared()
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = results?[indexPath.row] else {
            fatalError("There's no results but UIKit asked for a cell...")
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ArtistTableViewCell.reuseIdentifier,
            for: indexPath
        ) as! ArtistTableViewCell
        cell.viewModel = item
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        guard let results = results else { return }
        viewModel.onItemPressed(artist: results[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }
}

extension ArtistResultsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        viewModel.onSearchTextChanged(text: text)
    }
}

extension ArtistResultsTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.onSearchExit()
    }
}
