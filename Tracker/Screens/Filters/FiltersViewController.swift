import UIKit

enum TrackerFilter: CaseIterable {
    case all
    case today
    case completed
    case incomplete

    var title: String {
        switch self {
        case .all: return NSLocalizedString("All trackers", comment: "All trackers filter")
        case .today: return NSLocalizedString("Trackers for today", comment: "Today trackers filter")
        case .completed: return NSLocalizedString("Completed", comment: "Completed filter")
        case .incomplete: return NSLocalizedString("Incomplete", comment: "Incomplete filter")
        }
    }
}

final class FiltersViewController: UIViewController {

    // MARK: - UI
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private var tableViewHeightConstraint: NSLayoutConstraint?

    // MARK: - State
    var selectedFilter: TrackerFilter = .all
    var onFilterSelected: ((TrackerFilter) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updateTableViewHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTableViewHeight()
        tableView.reloadData()
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("Filters", comment: "Filters screen title")
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationController?.navigationBar.backgroundColor = UIColor.systemBackground
        navigationController?.navigationBar.barTintColor = UIColor.systemBackground
        navigationController?.view.backgroundColor = UIColor.systemBackground
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Filters", comment: "Filters screen title")
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor(named: "yBlackDay") ?? .label
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3) // #E6E8EB4D
        tableView.layer.cornerRadius = 16
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(FilterTableViewCell.self, forCellReuseIdentifier: FilterTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Как в категориях: убираем разделители в начале и конце
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        
        view.addSubview(tableView)
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 75)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 22),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableViewHeightConstraint!
        ])
    }
    
    private func updateTableViewHeight() {
        let rowCount = TrackerFilter.allCases.count
        let rowHeight: CGFloat = 75
        let totalHeight = CGFloat(rowCount) * rowHeight
        tableViewHeightConstraint?.constant = totalHeight
    }
}

// MARK: - UITableViewDataSource
extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TrackerFilter.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilterTableViewCell.identifier, for: indexPath) as! FilterTableViewCell
        let filter = TrackerFilter.allCases[indexPath.row]

        let isSelected = filter == selectedFilter
        // Галочка не показывается для .all и .today (это сброс фильтрации, а не установка фильтра)
        let shouldShowCheckmark = isSelected && filter != .all && filter != .today
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == TrackerFilter.allCases.count - 1
        cell.configure(title: filter.title, isSelected: shouldShowCheckmark, isFirst: isFirst, isLast: isLast)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedFilter = TrackerFilter.allCases[indexPath.row]
        tableView.reloadData()
        onFilterSelected?(selectedFilter)
        dismiss(animated: true)
    }
}

final class FilterTableViewCell: UITableViewCell {
    static let identifier = "FilterCell"

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        selectionStyle = .none

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear // Прозрачный фон, как в CategoryCell
        containerView.layer.cornerRadius = 0
        contentView.addSubview(containerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor(named: "yBlackDay") ?? .label
        containerView.addSubview(titleLabel)

        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = UIColor(red: 0/255, green: 121/255, blue: 255/255, alpha: 1)
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        containerView.addSubview(checkmarkImageView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 75),

            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -16),

            checkmarkImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(title: String, isSelected: Bool, isFirst: Bool, isLast: Bool) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected

        // Удаляем старые разделители
        containerView.subviews.filter { $0 != titleLabel && $0 != checkmarkImageView }.forEach { $0.removeFromSuperview() }
        
        // Добавляем разделитель, если не последняя ячейка
        if !isLast {
            let separatorView = UIView()
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            separatorView.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 0.3)
            containerView.addSubview(separatorView)
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
    }
}
