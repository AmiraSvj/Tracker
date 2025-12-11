import Foundation

protocol CategoryViewModelProtocol {
    var categories: [TrackerCategory] { get }
    var selectedCategory: TrackerCategory? { get }
    var onCategoriesUpdate: (() -> Void)? { get set }
    var onCategorySelected: ((TrackerCategory) -> Void)? { get set }
    var onCategoryCreated: ((TrackerCategory) -> Void)? { get set }

    func loadCategories()
    func selectCategory(_ category: TrackerCategory)
    func createCategory(title: String)
    func updateCategoryTitle(_ category: TrackerCategory, newTitle: String)
    func deleteCategory(_ category: TrackerCategory)
    
    // Старые методы для совместимости
    var categoriesDidUpdate: (() -> Void)? { get set }
    var selectedCategoryDidChange: ((String?) -> Void)? { get set }
    func numberOfCategories() -> Int
    func categoryTitle(at index: Int) -> String
    func isCategorySelected(at index: Int) -> Bool
    func selectCategory(at index: Int)
    func getSelectedCategory() -> String?
    func setSelectedCategory(_ categoryTitle: String?)
}

final class CategoryViewModel: CategoryViewModelProtocol {
    
    // MARK: - Bindings (через замыкания)
    var categoriesDidUpdate: (() -> Void)?
    var selectedCategoryDidChange: ((String?) -> Void)?
    
    // MARK: - Properties
    private let categoryStore: TrackerCategoryStoreProtocol
    private(set) var categories: [TrackerCategory] = []
    private(set) var selectedCategory: TrackerCategory?
    
    // MARK: - New Protocol Bindings
    var onCategoriesUpdate: (() -> Void)?
    var onCategorySelected: ((TrackerCategory) -> Void)?
    var onCategoryCreated: ((TrackerCategory) -> Void)?
    
    // MARK: - Initialization
    init(categoryStore: TrackerCategoryStoreProtocol = TrackerCategoryStore()) {
        self.categoryStore = categoryStore
        setupObservers()
        loadCategories()
    }
    
    deinit {
        categoryStore.stopObservingChanges()
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        categoryStore.startObservingChanges { [weak self] categories in
            self?.categories = categories
            self?.onCategoriesUpdate?()
            self?.categoriesDidUpdate?()
        }
    }
    
    // MARK: - Public Methods
    
    /// Загружает категории из модели (Core Data)
    func loadCategories() {
        categories = categoryStore.fetchCategories()
        categoriesDidUpdate?()
        onCategoriesUpdate?()
    }
    
    /// Возвращает количество категорий для таблицы
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    /// Возвращает название категории для ячейки по индексу
    func categoryTitle(at index: Int) -> String {
        guard index < categories.count else { return "" }
        return categories[index].title
    }
    
    /// Проверяет, выбрана ли категория
    func isCategorySelected(at index: Int) -> Bool {
        guard index < categories.count else { return false }
        return categories[index].title == selectedCategory?.title
    }
    
    /// Обрабатывает выбор категории пользователем (старый метод)
    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        let category = categories[index]
        selectCategory(category)
        selectedCategoryDidChange?(category.title)
    }
    
    /// Обрабатывает выбор категории (новый метод протокола)
    func selectCategory(_ category: TrackerCategory) {
        selectedCategory = category
        onCategorySelected?(category)
    }
    
    /// Создает новую категорию
    func createCategory(title: String) {
        let newCategory = categoryStore.createCategory(title: title)
        onCategoryCreated?(newCategory)
    }
    
    /// Обновляет название категории
    func updateCategoryTitle(_ category: TrackerCategory, newTitle: String) {
        categoryStore.updateCategoryTitle(category, newTitle: newTitle)
    }
    
    /// Удаляет категорию
    func deleteCategory(_ category: TrackerCategory) {
        categoryStore.deleteCategory(category)
    }
    
    /// Возвращает выбранную категорию
    func getSelectedCategory() -> String? {
        return selectedCategory?.title
    }
    
    /// Устанавливает выбранную категорию (для предварительного выбора)
    func setSelectedCategory(_ categoryTitle: String?) {
        if let title = categoryTitle {
            selectedCategory = categoryStore.getCategory(by: title)
        } else {
            selectedCategory = nil
        }
    }
}
