import UIKit

final class CategoryScreen: UIViewController {
    
    // MARK: - Properties
    weak var delegate: CategorySelectionDelegate?
    private let viewModel: CategoryViewModel
    private var selectedCategoryTitle: String?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        tableView.layer.cornerRadius = 16
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(selectedCategoryTitle: String? = nil) {
        self.viewModel = CategoryViewModel()
        self.selectedCategoryTitle = selectedCategoryTitle
        super.init(nibName: nil, bundle: nil)
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupNavigationBar()
        
        // Устанавливаем предварительно выбранную категорию
        if let selectedCategoryTitle = selectedCategoryTitle {
            viewModel.setSelectedCategory(selectedCategoryTitle)
        }
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Байндинг для обновления данных в таблице
        viewModel.categoriesDidUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateTableViewHeight()
                self?.tableView.reloadData()
            }
        }
        
        // Байндинг для обработки выбора категории
        viewModel.selectedCategoryDidChange = { [weak self] categoryTitle in
            guard let self = self, let categoryTitle = categoryTitle else { return }
            self.delegate?.didSelectCategory(categoryTitle)
            self.dismiss(animated: true)
        }
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 75)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableViewHeightConstraint!
        ])
        
        updateTableViewHeight()
    }
    
    private func updateTableViewHeight() {
        // Высота таблицы зависит от количества категорий (75px на ячейку)
        let numberOfCategories = viewModel.numberOfCategories()
        let tableViewHeight = CGFloat(max(1, numberOfCategories)) * 75
        tableViewHeightConstraint?.constant = tableViewHeight
    }
    
    private func setupNavigationBar() {
        title = "Категория"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
    }
}

// MARK: - UITableViewDataSource
extension CategoryScreen: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.identifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let categoryTitle = viewModel.categoryTitle(at: indexPath.row)
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        cell.configure(with: categoryTitle, isSelected: isSelected)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Обработка выбора через ViewModel
        viewModel.selectCategory(at: indexPath.row)
    }
}
