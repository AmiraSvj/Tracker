import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Trackers", comment: "Main screen title")
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor(named: "yBlackDay") ?? .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.locale = Locale(identifier: "ru_RU")
        picker.preferredDatePickerStyle = .compact
        picker.backgroundColor = .clear
        picker.translatesAutoresizingMaskIntoConstraints = false
        
        picker.addAction(UIAction { [weak self] _ in
            self?.handleDatePickerChange()
        }, for: .valueChanged)
        
        return picker
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("Search", comment: "Search placeholder")
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        searchBar.layer.cornerRadius = 8
        searchBar.clipsToBounds = true
        searchBar.delegate = self
        
        return searchBar
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0) // Отступ снизу для кнопки фильтров
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true // Оверскролл для прокрутки выше кнопки
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .star)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("What will we track?", comment: "Empty state placeholder")
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "yBlackDay") ?? .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var placeholderStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [placeholderImageView, placeholderLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Filters", comment: "Filters button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 0/255, green: 121/255, blue: 255/255, alpha: 1) // Blue
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        button.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    var completedTrackers: Set<TrackerRecord> = []
    private let calendar = Calendar.current
    var currentDate: Date {
        return datePicker.date
    }
    private var currentFilter: TrackerFilter = .all
    
    // MARK: - Core Data Stores
    
    private let categoryStore = TrackerCategoryStore()
    private let recordStore = TrackerRecordStore()
    private let trackerStore = TrackerStore()
    
    // MARK: - Context Menu
    
    private var contextMenuView: TrackerContextMenuView?
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigationBar()
        
        // Настраиваем delegate для автоматического обновления при изменениях в Core Data
        categoryStore.delegate = self
        
        loadData()
        refreshData()
        togglePlaceholderVisibility()
        updateFiltersButtonAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AnalyticsService.shared.report(event: .open, screen: .main)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.shared.report(event: .close, screen: .main)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    private func configureUI() {
        view.backgroundColor = UIColor.systemBackground
        
        view.addSubview(trackersLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderStack)
        view.addSubview(filtersButton)
        
        view.bringSubviewToFront(filtersButton) // Кнопка всегда поверх всех элементов
        
        configureConstraints()
    }
    
    private func configureNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(resource: .plus),
            style: .plain,
            target: self,
            action: #selector(handleAddTrackerTap)
        )
        addButton.tintColor = UIColor(named: "yBlackDay") ?? .label
        addButton.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        
        navigationItem.leftBarButtonItem = addButton
        navigationItem.rightBarButtonItem = datePickerItem
        
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets.zero
        navigationItem.leftBarButtonItem?.setBackgroundVerticalPositionAdjustment(0, for: .default)
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            trackersLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            trackersLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            searchBar.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Кнопка фильтров: центрирована по горизонтали, адаптивная ширина под разные устройства
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 114), // Минимальная ширина
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func handleAddTrackerTap() {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .addTrack)
        let createHabitVC = CreateHabitScreen()
        createHabitVC.delegate = self
        present(createHabitVC, animated: true)
    }
    
    private func handleDatePickerChange() {
        applyFiltersAndSearch()
        updateCompleteButtonsState()
    }
    
    private func refreshData() {
        // Перезагружаем данные из Core Data
        categories = categoryStore.fetchCategories()
        completedTrackers = recordStore.fetchRecords()
        
        applyFiltersAndSearch()
    }
    
    private func applyFiltersAndSearch() {
        let selectedDate = datePicker.date
        let calendarWeekday = calendar.component(.weekday, from: selectedDate)
        // Calendar.weekday: Sunday=1, Monday=2, ..., Saturday=7
        // Weekday enum: Monday=1, Tuesday=2, ..., Sunday=7
        let filterWeekday: Int
        if calendarWeekday == 1 {
            filterWeekday = 7 // Sunday
        } else {
            filterWeekday = calendarWeekday - 1 // Monday=1, Tuesday=2, etc.
        }
        
        // Получаем текст поиска
        let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        
        // Собираем все закрепленные трекеры
        var pinnedTrackers: [Tracker] = []
        var unpinnedCategories: [TrackerCategory] = []
        
        for category in categories {
            let pinnedInCategory = category.trackers.filter { $0.isPinned }
            let unpinnedInCategory = category.trackers.filter { !$0.isPinned }
            
            pinnedTrackers.append(contentsOf: pinnedInCategory)
            
            if !unpinnedInCategory.isEmpty {
                // Фильтруем по расписанию
                var filteredUnpinned = unpinnedInCategory.filter { tracker in
                    tracker.schedule.contains { weekday in
                        weekday.numericValue == filterWeekday
                    }
                }
                
                // Применяем поиск, если есть текст
                if !searchText.isEmpty {
                    filteredUnpinned = filteredUnpinned.filter { tracker in
                        tracker.title.lowercased().contains(searchText)
                    }
                }
                
                if !filteredUnpinned.isEmpty {
                    unpinnedCategories.append(TrackerCategory(title: category.title, trackers: filteredUnpinned))
                }
            }
        }
        
        // Фильтруем закрепленные трекеры по расписанию и поиску
        var filteredPinnedTrackers = pinnedTrackers.filter { tracker in
            tracker.schedule.contains { weekday in
                weekday.numericValue == filterWeekday
            }
        }
        
        // Применяем поиск к закрепленным трекерам
        if !searchText.isEmpty {
            filteredPinnedTrackers = filteredPinnedTrackers.filter { tracker in
                tracker.title.lowercased().contains(searchText)
            }
        }
        
        // Формируем видимые категории: сначала "Закрепленные", затем остальные
        var allCategories: [TrackerCategory] = []
        if !filteredPinnedTrackers.isEmpty {
            allCategories.append(TrackerCategory(title: "Закрепленные", trackers: filteredPinnedTrackers))
        }
        allCategories.append(contentsOf: unpinnedCategories)
        
        // Применяем фильтры
        visibleCategories = applyFilters(to: allCategories)
        
        collectionView.reloadData()
        togglePlaceholderVisibility()
        updateFiltersButtonAppearance()
    }
    
    private func applyFilters(to categories: [TrackerCategory]) -> [TrackerCategory] {
        var filteredCategories = categories
        
        switch currentFilter {
        case .all:
            // Показываем все трекеры
            break
            
        case .today:
            // Показываем только трекеры на сегодня (уже отфильтровано по дате в applyFiltersAndSearch)
            // Фильтр "Сегодня" просто показывает все трекеры, запланированные на выбранную дату
            break
            
        case .completed:
            // Показываем только завершенные трекеры
            filteredCategories = categories.map { category in
                let completedTrackers = category.trackers.filter { tracker in
                    isTrackerCompletedToday(tracker.identifier)
                }
                return TrackerCategory(title: category.title, trackers: completedTrackers)
            }.filter { !$0.trackers.isEmpty }
            
        case .incomplete:
            // Показываем только незавершенные трекеры
            filteredCategories = categories.map { category in
                let incompleteTrackers = category.trackers.filter { tracker in
                    !isTrackerCompletedToday(tracker.identifier)
                }
                return TrackerCategory(title: category.title, trackers: incompleteTrackers)
            }.filter { !$0.trackers.isEmpty }
        }
        
        return filteredCategories
    }
    
    @objc private func filtersButtonTapped() {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .filter)
        let filtersVC = FiltersViewController()
        filtersVC.modalPresentationStyle = .pageSheet
        filtersVC.selectedFilter = currentFilter
        filtersVC.onFilterSelected = { [weak self] filter in
            guard let self = self else { return }
            self.currentFilter = filter
            
            // Если выбран фильтр "Трекеры на сегодня", устанавливаем текущую дату
            if filter == .today {
                self.datePicker.setDate(Date(), animated: true)
            }
            
            self.applyFiltersAndSearch()
            self.updateFiltersButtonAppearance()
        }
        present(filtersVC, animated: true)
    }
    
    private func updateCompleteButtonsState() {
        for case let cell as TrackerCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
            let isCompletedToday = isTrackerCompletedToday(tracker.identifier)
            
            cell.updateCompleteButton(isCompletedToday: isCompletedToday, color: tracker.color)
        }
    }
    
    private func updateFiltersButtonAppearance() {
        // Визуальный сигнал активного фильтра: красный цвет текста когда фильтр активен
        // Белый цвет - фильтр не активен (.all или .today)
        let isFilterActive = currentFilter != .all && currentFilter != .today
        let textColor = isFilterActive ? UIColor(red: 245/255, green: 107/255, blue: 108/255, alpha: 1) : .white
        filtersButton.setTitleColor(textColor, for: .normal)
    }
    
    private func togglePlaceholderVisibility() {
        let hasVisibleTrackers = visibleCategories.contains { !$0.trackers.isEmpty }
        let isEmpty = visibleCategories.isEmpty
        
        // Кнопка фильтров всегда видна, если есть трекеры в базе
        let hasAnyTrackers = categories.contains { !$0.trackers.isEmpty }
        filtersButton.isHidden = !hasAnyTrackers
        
        placeholderStack.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
        
        // Проверяем, есть ли активный поиск или фильтр
        let searchText = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasActiveSearch = !searchText.isEmpty
        let hasActiveFilter = currentFilter != .all
        
        // Обновляем изображение и текст заглушки
        if isEmpty {
            if hasActiveSearch || hasActiveFilter {
                // При поиске или фильтре показываем картинку il2
                // Изображение находится в Assets: il 2/error/2.imageset
                // Используем имя imageset напрямую
                if let errorImage = UIImage(named: "2") {
                    placeholderImageView.image = errorImage
                } else {
                    // Fallback на звездочку, если изображение не найдено
                    placeholderImageView.image = UIImage(resource: .star)
                }
                placeholderLabel.text = NSLocalizedString("Nothing found", comment: "No results placeholder")
            } else {
                // При пустом состоянии показываем звездочку
                placeholderImageView.image = UIImage(resource: .star)
                placeholderLabel.text = NSLocalizedString("What will we track?", comment: "Empty state placeholder")
            }
        }
    }
    
    private func isTrackerCompletedToday(_ trackerId: UUID) -> Bool {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        return completedTrackers.contains(TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate))
    }
    
    private func completeTracker(_ trackerId: UUID) {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .track)
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let today = Date()
        
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        let normalizedToday = calendar.startOfDay(for: today)
        
        guard normalizedSelectedDate <= normalizedToday else { return }
        
        let record = TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate)
        recordStore.addRecord(record)
        completedTrackers.insert(record)
        
        print("✅ Completed trackers count: \(completedTrackers.count)")
        print("✅ For tracker \(trackerId): \(completedTrackers.filter { $0.trackerId == trackerId }.count) records")
        
        if let indexPath = findIndexPathForTracker(with: trackerId) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    private func uncompleteTracker(_ trackerId: UUID) {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        
        let record = TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate)
        recordStore.deleteRecord(record)
        completedTrackers.remove(record)
        
        if let indexPath = findIndexPathForTracker(with: trackerId) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    private func findIndexPathForTracker(with id: UUID) -> IndexPath? {
        for (sectionIndex, category) in visibleCategories.enumerated() {
            for (itemIndex, tracker) in category.trackers.enumerated() {
                if tracker.identifier == id {
                    return IndexPath(item: itemIndex, section: sectionIndex)
                }
            }
        }
        return nil
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        // Загружаем категории из Core Data
        categories = categoryStore.fetchCategories()
        
        // Загружаем записи о выполненных трекерах из Core Data
        completedTrackers = recordStore.fetchRecords()
        
        // Категории загружаются из Core Data, начальная категория не создается
    }
    
    private func saveData() {
        // Сохранение происходит автоматически через Store классы при изменениях
        CoreDataManager.shared.saveContext()
    }
    
    // MARK: - Context Menu
    
    private func showContextMenu(for tracker: Tracker, at indexPath: IndexPath) {
        hideContextMenu()
        
        let contextMenu = TrackerContextMenuView()
        contextMenu.delegate = self
        contextMenu.configure(with: tracker)
        contextMenu.translatesAutoresizingMaskIntoConstraints = false
        
        // Получаем координаты ячейки
        guard let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath) else { return }
        let cellRect = cellAttributes.frame
        let cellRectInView = collectionView.convert(cellRect, to: view)
        
        // Высота карточки (colorView) - 90px, без счетчика и кнопки
        let cardHeight: CGFloat = 90
        let cardRect = CGRect(
            x: cellRectInView.minX,
            y: cellRectInView.minY,
            width: cellRectInView.width,
            height: cardHeight
        )
        
        // Счетчик и кнопка находятся ниже карточки
        // Счетчик: top = cardRect.maxY + 16, высота = 18
        // Кнопка: top = cardRect.maxY + 8, высота = 34
        // Позиционируем меню так, чтобы оно перекрывало счетчик и кнопку
        // Меню начинается прямо на уровне кнопки (cardRect.maxY + 8), чтобы полностью перекрыть ее
        let menuTopOffset = cardRect.maxY + 8 // Позиционируем меню на уровне кнопки плюса
        
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
        
        // Устанавливаем z-order: меню должно быть поверх всего (включая счетчик и кнопку плюса)
        view.bringSubviewToFront(contextMenu)
        
        NSLayoutConstraint.activate([
            contextMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contextMenu.topAnchor.constraint(equalTo: view.topAnchor, constant: menuTopOffset)
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
        
        // Вычисляем координаты карточки относительно snapshot
        let cardRectInSnapshot = view.convert(cardRect, to: snapshot)
        
        DispatchQueue.main.async {
            let maskLayer = CAShapeLayer()
            let path = UIBezierPath(rect: snapshot.bounds)
            
            // Создаем "дырку" ТОЛЬКО для карточки трекера (90px высота)
            // Счетчик дней и кнопка плюса находятся ниже и будут заблюрены
            let cardHolePath = UIBezierPath(roundedRect: cardRectInSnapshot, cornerRadius: 16)
            path.append(cardHolePath.reversing())
            
            // Создаем "дырку" для меню (высота увеличена до 145.5 для трех кнопок)
            let menuRectInSnapshot = CGRect(
                x: 16,
                y: cardRectInSnapshot.maxY + 8,
                width: 250,
                height: 145.5
            )
            let menuHolePath = UIBezierPath(roundedRect: menuRectInSnapshot, cornerRadius: 13)
            path.append(menuHolePath.reversing())
            
            maskLayer.path = path.cgPath
            snapshot.layer.mask = maskLayer
        }
        
        // Добавляем tap gesture для закрытия меню
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideContextMenu))
        snapshot.addGestureRecognizer(tapGesture)
    }
    
    @objc private func hideContextMenu() {
        contextMenuView?.removeFromSuperview()
        contextMenuView = nil
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }
    
    private func findCategoryForTracker(_ trackerId: UUID) -> TrackerCategory? {
        return categories.first { category in
            category.trackers.contains { $0.identifier == trackerId }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let completedDays = completedTrackers.filter { $0.trackerId == tracker.identifier }.count
        
        print("🔄 Configuring cell - completedDays: \(completedDays) for tracker: \(tracker.identifier)")
        
        let isCompletedToday = isTrackerCompletedToday(tracker.identifier)
        
        cell.configure(
            with: tracker,
            completedDays: completedDays,
            isCompletedToday: isCompletedToday
        )
        
        cell.onCompleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            let isCurrentlyCompleted = self.isTrackerCompletedToday(tracker.identifier)
            if isCurrentlyCompleted {
                self.uncompleteTracker(tracker.identifier)
            } else {
                self.completeTracker(tracker.identifier)
            }
        }
        
        cell.onLongPress = { [weak self] tracker in
            guard let self = self else { return }
            self.showContextMenu(for: tracker, at: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as? HeaderView else {
            return UICollectionReusableView()
        }
        
        header.configure(with: visibleCategories[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Размер карточки: width: 167, height: 148
        return CGSize(width: 167, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 46)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    }
}

// MARK: - UISearchBarDelegate
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFiltersAndSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        applyFiltersAndSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        // Добавляем трекер в категорию через Store
        categoryStore.addTracker(tracker, toCategoryTitle: categoryTitle)
        
        // Обновляем локальные данные
        categories = categoryStore.fetchCategories()
        
        print("📝 Added tracker: \(tracker.title)")
        print("📝 Schedule: \(tracker.schedule.map { $0.displayName })")
        print("📝 Total categories: \(categories.count)")
        print("📝 Total trackers in category '\(categoryTitle)': \(categories.first(where: { $0.title == categoryTitle })?.trackers.count ?? 0)")
        
        applyFiltersAndSearch()
        
        dismiss(animated: true)
    }
    
    func didUpdateTracker(_ tracker: Tracker, categoryTitle: String) {
        // Обновляем трекер через Store (обновляет данные трекера в Core Data)
        trackerStore.updateTracker(tracker)
        
        // Удаляем трекер из старой категории, если категория изменилась
        if let oldCategory = findCategoryForTracker(tracker.identifier),
           oldCategory.title != categoryTitle {
            categoryStore.removeTracker(tracker.identifier, fromCategoryTitle: oldCategory.title)
            categoryStore.addTracker(tracker, toCategoryTitle: categoryTitle)
        }
        // Если категория не изменилась, трекер уже обновлен через trackerStore.updateTracker
        
        // Обновляем локальные данные
        categories = categoryStore.fetchCategories()
        
        applyFiltersAndSearch()
        
        dismiss(animated: true)
    }
}

// MARK: - TrackerCategoryStoreDelegate

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func storeDidUpdate() {
        // Автоматическое обновление при изменениях в Core Data через NSFetchedResultsController
        DispatchQueue.main.async { [weak self] in
            self?.categories = self?.categoryStore.fetchCategories() ?? []
            self?.applyFiltersAndSearch()
        }
    }
}

// MARK: - TrackerContextMenuViewDelegate

extension TrackersViewController: TrackerContextMenuViewDelegate {
    func didTapEditTracker(_ tracker: Tracker) {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .edit)
        hideContextMenu()
        
        guard let category = findCategoryForTracker(tracker.identifier) else {
            return
        }
        
        let editScreen = CreateHabitScreen(editingTracker: tracker, categoryTitle: category.title)
        editScreen.delegate = self
        editScreen.modalPresentationStyle = .pageSheet
        present(editScreen, animated: true)
    }
    
    func didTapPinTracker(_ tracker: Tracker) {
        hideContextMenu()
        
        // Переключаем состояние закрепления и обновляем UI после сохранения
        trackerStore.togglePinTracker(tracker) { [weak self] in
            guard let self = self else { return }
            // Обновляем данные после того, как изменения сохранены в Core Data
            self.categories = self.categoryStore.fetchCategories()
            self.applyFiltersAndSearch()
        }
    }
    
    func didTapDeleteTracker(_ tracker: Tracker) {
        AnalyticsService.shared.report(event: .click, screen: .main, item: .delete)
        hideContextMenu()
        
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("Are you sure you want to delete the tracker?", comment: "Delete confirmation"),
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete button"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Удаляем трекер из категории
            if let category = self.findCategoryForTracker(tracker.identifier) {
                self.categoryStore.removeTracker(tracker.identifier, fromCategoryTitle: category.title)
            }
            
            // Удаляем трекер из Core Data
            self.trackerStore.deleteTracker(withId: tracker.identifier)
            
            // Обновляем данные
            self.categories = self.categoryStore.fetchCategories()
            self.applyFiltersAndSearch()
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel))
        
        present(alert, animated: true)
    }
}

