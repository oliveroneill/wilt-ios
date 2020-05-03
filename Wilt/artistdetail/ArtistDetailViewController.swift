import UIKit
import Charts

/// A controller for displaying a more detailed look at the user's activity in relation to a specific artist
class ArtistDetailViewController: UITableViewController {
    private let viewModel: ArtistDetailViewModel
    /// A graph showing the listens per month
    private lazy var chart: BarChartView = {
        let chart = BarChartView()
        chart.noDataText = ""
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()
    /// A cell for displaying the artist's name and a picture
    private let artistCell = ArtistDetailTitleCell(
        style: .default,
        reuseIdentifier: nil
    )
    /// The tableview cell holding the chart
    private lazy var chartCell: UITableViewCell = {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        chart.isUserInteractionEnabled = true
        cell.addSubview(chart)
        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            chart.bottomAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            chart.leadingAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            chart.trailingAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
        return cell
    }()
    /// A loading spinner that will be displayed while activity stats for the graph are loading
    private lazy var chartLoadingSpinner: UIActivityIndicatorView = {
        let loadingSpinner = UIActivityIndicatorView(frame: .zero)
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        chartCell.addSubview(loadingSpinner)
        NSLayoutConstraint.activate([
            loadingSpinner.topAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            loadingSpinner.bottomAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            loadingSpinner.leadingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            loadingSpinner.trailingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
        return loadingSpinner
    }()
    /// An error message label to be displayed if something goes wrong fetching the chart data
    private lazy var chartErrorMessageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        chartCell.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            label.bottomAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            label.leadingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            label.trailingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
        return label
    }()
    /// A label for displaying the chart title. Charts does have a chartDescription field but this doesn't
    /// support positioning with autolayout
    private lazy var chartTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "artist_detail_chart_title".localized
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        chartCell.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.topAnchor,
                constant: 8
            ),
            label.leadingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            label.trailingAnchor.constraint(
                equalTo: chartCell.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            label.heightAnchor.constraint(equalToConstant: 10),
        ])
        return label
    }()
    /// A cell that which the user will tap to open an artist's page in Spotify
    private lazy var openCell: UITableViewCell = {
        let cell = UITableViewCell()
        let label: UILabel = {
            let label = UILabel(frame: .zero)
            label.font = .boldSystemFont(ofSize: 16)
            return label
        }()
        label.text = "artist_detail_open_cell_title".localized
        cell.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            label.bottomAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            label.leadingAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            label.trailingAnchor.constraint(
                equalTo: cell.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
        return cell
    }()

    init(viewModel: ArtistDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = "artist_detail_title".localized
        view.backgroundColor = .white
        tableView.tableFooterView = UIView(frame: .zero)
        viewModel.onViewUpdate = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateState(state: state)
                self?.tableView.reloadData()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        // We use viewWillAppear so that the controller is initialised and we
        // can ensure that the state is correctly set before the view is
        // displayed (otherwise the artist info is missing for a second)
        viewModel.onViewLoaded()
    }

    /// A custom formatter for labelling bars based on string values
    class CustomXAxisLabelFormatter: IAxisValueFormatter {
        private let values: [String]

        /// Initialise the formatter
        /// - Parameter values: X-axis labels where the index will be its x value
        init(values: [String]) {
            self.values = values
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            values[Int(value)]
        }
    }

    private func updateState(state: ArtistDetailViewModelState) {
        chartErrorMessageLabel.isHidden = true
        switch state {
        case .loading(artist: let artist):
            chartLoadingSpinner.startAnimating()
            // Remove current graph data
            chart.data = nil
            artistCell.viewModel = artist
        case .loaded(artist: let artist, activity: let activity):
            chartTitleLabel.isHidden = false
            // Stop the spinner
            chartLoadingSpinner.stopAnimating()
            artistCell.viewModel = artist
            showArtistActivity(activity: activity)
        case .error(errorMessage: let message):
            chartLoadingSpinner.stopAnimating()
            chartErrorMessageLabel.text = message
            chartErrorMessageLabel.isHidden = false
        }
    }

    private func showArtistActivity(activity: [ActivityPeriodViewData]) {
        // Setup the graph to be displayed
        let dataSet = BarChartDataSet(entries: activity.enumerated().map {
            BarChartDataEntry(x: Double($0.0), y: Double($0.1.numberOfPlays))
        })
        dataSet.colors = [UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)]
        dataSet.drawValuesEnabled = false
        chart.xAxis.valueFormatter = CustomXAxisLabelFormatter(
            values: activity.map { $0.dateText }
        )
        chart.data = BarChartData(dataSet: dataSet)
        chart.dragXEnabled = true
        chart.setScaleEnabled(false)
        chart.drawValueAboveBarEnabled = false
        chart.leftAxis.axisMinimum = 0
        chart.rightAxis.enabled = false
        chart.legend.enabled = false
        chart.leftAxis.drawGridLinesEnabled = false
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.labelPosition = .bottom
        chart.drawGridBackgroundEnabled = false
        // Set a page size where each page will be 6 months worth of activity
        let pageSize = Double(min(activity.count, 6))
        chart.setVisibleXRange(minXRange: pageSize, maxXRange: pageSize)
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 112
        case 1:
            return 300
        case 2:
            return 50
        default:
            fatalError("Unexpected index: \(indexPath.row)")
        }
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return artistCell
        case 1:
            return chartCell
        case 2:
            return openCell
        default:
            fatalError("Unexpected index: \(indexPath.row)")
        }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 2:
            viewModel.openCellTapped()
        default:
            break
        }
    }
}
