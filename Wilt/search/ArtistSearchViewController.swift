import UIKit

/// A search controller for allowing the user to search for an artist to add to their list
class ArtistSearchViewController: UITableViewController {
    private let searchController: UISearchController
    private let resultsController: ArtistResultsTableViewController

    init(viewModel: ArtistSearchViewModel) {
        resultsController = ArtistResultsTableViewController(
            viewModel: viewModel
        )
        searchController = UISearchController(
            searchResultsController: resultsController
        )
        super.init(nibName: nil, bundle: nil)
        tableView.tableFooterView = UIView(frame: .zero)
        searchController.searchResultsUpdater = resultsController
        searchController.searchBar.delegate = resultsController
        searchController.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "listen_later_search_placeholder_text".localized
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        // Use the results controller to know whether to show the
        // spinner on the search bar or not
        resultsController.onLoadingStateChanged = { [weak self] loading in
           self?.searchController.searchBar.isLoading = loading
       }
        definesPresentationContext = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        // Necessary to show the keyboard immediately
        searchController.isActive = true
    }
}

extension ArtistSearchViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        // We need to call this asynchronously because otherwise it's
        // called too early and the keyboard is not displayed
        DispatchQueue.main.async {
            searchController.searchBar.becomeFirstResponder()
        }
    }
}
