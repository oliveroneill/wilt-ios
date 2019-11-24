/// View for displaying settings but also doing a bit of double duty for
/// displaying some info about the app
final class SettingsViewController: UITableViewController {
    private let loggedIn: Bool
    private lazy var aboutLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = "about_text".localized
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var aboutCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.addSubview(aboutLabel)
        // Used for KIF testing
        cell.accessibilityLabel = "about_cell"
        return cell
    }()

    private lazy var logOutLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = "logout_text".localized
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var logOutCell: UITableViewCell = {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.addSubview(logOutLabel)
        // Used for KIF testing
        cell.accessibilityLabel = "logout_cell"
        return cell
    }()
    weak var delegate: SettingsViewControllerDelegate?

    /// Create a SettingsViewController
    ///
    /// - Parameter loggedIn: Whether to show the log-out button or not
    init(loggedIn: Bool = true) {
        self.loggedIn = loggedIn
        super.init(nibName: nil, bundle: nil)
        title = "settings_title_text".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeSettings)
        )
        NSLayoutConstraint.activate([
            aboutLabel.topAnchor.constraint(
                equalTo: aboutCell.topAnchor,
                constant: 16
            ),
            aboutLabel.bottomAnchor.constraint(
                equalTo: aboutCell.bottomAnchor,
                constant: -16
            ),
            aboutLabel.leadingAnchor.constraint(
                equalTo: aboutCell.leadingAnchor,
                constant: 16
            ),
            aboutLabel.trailingAnchor.constraint(
                equalTo: aboutCell.trailingAnchor,
                constant: -16
            ),
        ])
        NSLayoutConstraint.activate([
            logOutLabel.topAnchor.constraint(
                equalTo: logOutCell.topAnchor,
                constant: 16
            ),
            logOutLabel.bottomAnchor.constraint(
                equalTo: logOutCell.bottomAnchor,
                constant: -16
            ),
            logOutLabel.leadingAnchor.constraint(
                equalTo: logOutCell.leadingAnchor,
                constant: 16
            ),
            logOutLabel.trailingAnchor.constraint(
                equalTo: logOutCell.trailingAnchor,
                constant: -16
            ),
        ])
        // To hide the cells at the bottom
        tableView.tableFooterView = UIView(frame: .zero)
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 + (loggedIn ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return aboutCell
        case 1:
            return logOutCell
        default:
            fatalError("An unexpected section was found")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "about_title_text".localized
        case 1:
            return "logout_title_text".localized
        default:
            fatalError("An unexpected section was found")
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            delegate?.contactUs()
        case 1:
            delegate?.logOut()
        default:
            fatalError("An unexpected section was found")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc private func closeSettings() {
        delegate?.close()
    }
}

protocol SettingsViewControllerDelegate: class {
    func contactUs()
    func close()
    func logOut()
}
