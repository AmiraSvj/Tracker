import UIKit

final class CategoryScreen: UIViewController {
    
    // MARK: - Properties
    weak var delegate: CategorySelectionDelegate?
    private let viewModel: CategoryViewModel
    private var selectedCategoryTitle: String?
    private var contextMenuView: CategoryContextMenuView?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3) // #E6E8EB4D
        tableView.isScrollEnabled = false // Отключаем скролл, так как высота будет динамической
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        
        // Как в расписании: убираем разделители в начале и конце
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        
        return tableView
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить категорию", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 19, left: 32, bottom: 19, right: 32)
        button.addTarget(self, action: #selector(addCategoryButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .star)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Привычки и события можно\nобъединить по смыслу"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(selectedCategoryTitle: String? = nil) {
        self.viewModel = CategoryViewModel()
        self.selectedCategoryTitle = selectedCategoryTitle
        super.init(nibName: nil, bundle: nil)
        setupBindings()
        // Загружаем категории сразу при инициализации
        viewModel.loadCategories()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // FFFFFF
        setupUI()
        setupNavigationBar()
        
        // Устанавливаем предварительно выбранную категорию
        if let selectedCategoryTitle = selectedCategoryTitle {
            viewModel.setSelectedCategory(selectedCategoryTitle)
        }
        
        // Обновляем высоту таблицы после загрузки данных
        DispatchQueue.main.async { [weak self] in
            self?.updateTableViewHeight()
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем высоту таблицы при появлении экрана
        updateTableViewHeight()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Байндинг для обновления данных в таблице
        viewModel.categoriesDidUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateTableViewHeight()
                self?.updateUI()
                self?.tableView.reloadData()
            }
        }
        
        // Байндинг для обработки выбора категории
        viewModel.selectedCategoryDidChange = { [weak self] categoryTitle in
            guard let self = self, let categoryTitle = categoryTitle else { return }
            self.delegate?.didSelectCategory(categoryTitle)
            self.dismiss(animated: true)
        }
        
        // Байндинг для обновления после создания категории
        viewModel.onCategoriesUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateTableViewHeight()
                self?.updateUI()
                self?.tableView.reloadData()
            }
        }
        
        // Байндинг для автоматического выбора созданной категории
        viewModel.onCategoryCreated = { [weak self] category in
            DispatchQueue.main.async {
                self?.viewModel.selectCategory(category)
            }
        }
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(addCategoryButton)
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 75)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableViewHeightConstraint!,
            
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 58)
        ])
        
        updateUI()
    }
    
    private func updateTableViewHeight() {
        // Высота таблицы зависит от количества категорий (75px на ячейку)
        let numberOfCategories = viewModel.numberOfCategories()
        let tableViewHeight = CGFloat(numberOfCategories) * 75
        tableViewHeightConstraint?.constant = max(tableViewHeight, 0)
    }
    
    private func updateUI() {
        let hasCategories = viewModel.numberOfCategories() > 0
        tableView.isHidden = !hasCategories
        emptyStateImageView.isHidden = hasCategories
        emptyStateLabel.isHidden = hasCategories
    }
    
    private func setupNavigationBar() {
        title = "Категория"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ]
        navigationController?.navigationBar.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationController?.navigationBar.barTintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationController?.view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
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
    
    // MARK: - Actions
    @objc private func addCategoryButtonTapped() {
        let createCategoryVC = CreateCategoryViewController(viewModel: viewModel)
        createCategoryVC.modalPresentationStyle = .pageSheet
        present(createCategoryVC, animated: true)
    }
    
    // MARK: - Context Menu
    private func showContextMenu(for category: TrackerCategory, at indexPath: IndexPath) {
        hideContextMenu()
        
        let contextMenu = CategoryContextMenuView()
        contextMenu.delegate = self
        contextMenu.configure(with: category)
        contextMenu.translatesAutoresizingMaskIntoConstraints = false
        
        // Позиционируем меню под полем категории
        let cellRect = tableView.rectForRow(at: indexPath)
        let cellRectInView = tableView.convert(cellRect, to: view)
        
        // Создаем snapshot фона для размытия ПЕРЕД добавлением меню
        let snapshot = view.snapshotView(afterScreenUpdates: false) ?? UIView()
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        snapshot.tag = 999
        
        // Добавляем snapshot сначала (будет ниже всех)
        view.addSubview(snapshot)
        
        NSLayoutConstraint.activate([
            snapshot.topAnchor.constraint(equalTo: view.topAnchor),
            snapshot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snapshot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Затем добавляем меню ПОВЕРХ snapshot и всех других элементов
        view.addSubview(contextMenu)
        
        // Устанавливаем z-order: меню должно быть поверх всего
        view.bringSubviewToFront(contextMenu)
        
        NSLayoutConstraint.activate([
            contextMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contextMenu.topAnchor.constraint(equalTo: view.topAnchor, constant: cellRectInView.maxY + 8)
        ])
        
        contextMenuView = contextMenu
        
        // Добавляем blur эффект
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        snapshot.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: snapshot.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: snapshot.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: snapshot.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: snapshot.bottomAnchor)
        ])
        
        DispatchQueue.main.async {
            let maskLayer = CAShapeLayer()
            let path = UIBezierPath(rect: snapshot.bounds)
            
            // Получаем rect ячейки и конвертируем в координаты view
            let cellRect = self.tableView.rectForRow(at: indexPath)
            let cellRectInView = self.tableView.convert(cellRect, to: self.view)
            
            // Контейнер ячейки занимает всю ширину tableView (которая уже имеет отступы 16px)
            // Поэтому используем точные координаты ячейки без дополнительных отступов
            let containerHoleRect = CGRect(
                x: cellRectInView.minX,
                y: cellRectInView.minY,
                width: cellRectInView.width,
                height: cellRectInView.height
            )
            let containerHolePath = UIBezierPath(roundedRect: containerHoleRect, cornerRadius: 16)
            path.append(containerHolePath)
            
            // Добавляем "дырку" для контекстного меню
            let menuRect = contextMenu.convert(contextMenu.bounds, to: self.view)
            let menuHolePath = UIBezierPath(roundedRect: menuRect, cornerRadius: 13)
            path.append(menuHolePath)
            
            maskLayer.path = path.cgPath
            maskLayer.fillRule = .evenOdd
            snapshot.layer.mask = maskLayer
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
        snapshot.addGestureRecognizer(tapGesture)
    }
    
    @objc private func hideContextMenu() {
        contextMenuView?.removeFromSuperview()
        contextMenuView = nil
        view.viewWithTag(999)?.removeFromSuperview()
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
        
        let category = viewModel.categories[indexPath.row]
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        cell.configure(with: category, isSelected: isSelected)
        
        // Как в расписании: устанавливаем separatorInset
        cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        cell.onLongPress = { [weak self] category in
            self?.showContextMenu(for: category, at: indexPath)
        }
        
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
        hideContextMenu()
        // Обработка выбора через ViewModel
        viewModel.selectCategory(at: indexPath.row)
    }
    
}

// MARK: - CategoryContextMenuViewDelegate
extension CategoryScreen: CategoryContextMenuViewDelegate {
    func didTapEditCategory(_ category: TrackerCategory) {
        hideContextMenu()
        
        let editCategoryVC = EditCategoryViewController(category: category)
        editCategoryVC.delegate = self
        editCategoryVC.modalPresentationStyle = .pageSheet
        present(editCategoryVC, animated: true)
    }
    
    func didTapDeleteCategory(_ category: TrackerCategory) {
        hideContextMenu()
        
        let alert = UIAlertController(
            title: "Удалить категорию?",
            message: "Это действие нельзя отменить",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(category)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - EditCategoryViewControllerDelegate
extension CategoryScreen: EditCategoryViewControllerDelegate {
    func didUpdateCategory(_ category: TrackerCategory, newTitle: String) {
        viewModel.updateCategoryTitle(category, newTitle: newTitle)
    }
}
