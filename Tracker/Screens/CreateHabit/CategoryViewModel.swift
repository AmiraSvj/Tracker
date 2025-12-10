import Foundation

final class CategoryViewModel {
    
    // MARK: - Bindings (через замыкания)
    var categoriesDidUpdate: (() -> Void)?
    var selectedCategoryDidChange: ((String?) -> Void)?
    
    // MARK: - Properties
    private let categoryStore: TrackerCategoryStore
    private(set) var categories: [TrackerCategory] = []
    private(set) var selectedCategoryTitle: String?
    
    // MARK: - Initialization
    init(categoryStore: TrackerCategoryStore = TrackerCategoryStore()) {
        self.categoryStore = categoryStore
        loadCategories()
    }
    
    // MARK: - Public Methods
    
    /// Загружает категории из модели (Core Data)
    func loadCategories() {
        categories = categoryStore.fetchCategories()
        categoriesDidUpdate?()
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
        return categories[index].title == selectedCategoryTitle
    }
    
    /// Обрабатывает выбор категории пользователем
    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        selectedCategoryTitle = categories[index].title
        selectedCategoryDidChange?(selectedCategoryTitle)
    }
    
    /// Возвращает выбранную категорию
    func getSelectedCategory() -> String? {
        return selectedCategoryTitle
    }
    
    /// Устанавливает выбранную категорию (для предварительного выбора)
    func setSelectedCategory(_ categoryTitle: String?) {
        selectedCategoryTitle = categoryTitle
    }
}
