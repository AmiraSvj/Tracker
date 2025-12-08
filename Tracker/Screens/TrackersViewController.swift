import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private lazy var trackersLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
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
        searchBar.placeholder = "Поиск"
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
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .star)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
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
    
    // MARK: - Properties
    
    var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    var completedTrackers: Set<TrackerRecord> = []
    private let calendar = Calendar.current
    var currentDate: Date {
        return datePicker.date
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigationBar()
        loadData()
        refreshData()
        togglePlaceholderVisibility()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveData),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveData),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Methods
    
    private func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(trackersLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(placeholderStack)
        
        configureConstraints()
    }
    
    private func configureNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(resource: .plus),
            style: .plain,
            target: self,
            action: #selector(handleAddTrackerTap)
        )
        addButton.tintColor = .black
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
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            searchBar.topAnchor.constraint(equalTo: trackersLabel.bottomAnchor, constant: 7),
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            placeholderImageView.widthAnchor.constraint(equalToConstant: 80),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func handleAddTrackerTap() {
        let createHabitVC = CreateHabitScreen()
        createHabitVC.delegate = self
        present(createHabitVC, animated: true)
    }
    
    private func handleDatePickerChange() {
        refreshData()
        updateCompleteButtonsState()
    }
    
    private func refreshData() {
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
        
        visibleCategories = categories.map { category in
            let filteredTrackers = category.trackers.filter { tracker in
                tracker.schedule.contains { weekday in
                    weekday.numericValue == filterWeekday
                }
            }
            return TrackerCategory(title: category.title, trackers: filteredTrackers)
        }.filter { !$0.trackers.isEmpty }
        
        collectionView.reloadData()
        togglePlaceholderVisibility()
    }
    
    private func updateCompleteButtonsState() {
        for case let cell as TrackerCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
            let isCompletedToday = isTrackerCompletedToday(tracker.identifier)
            
            cell.updateCompleteButton(isCompletedToday: isCompletedToday, color: tracker.color)
        }
    }
    
    private func togglePlaceholderVisibility() {
        let hasVisibleTrackers = visibleCategories.contains { !$0.trackers.isEmpty }
        placeholderStack.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
    }
    
    private func isTrackerCompletedToday(_ trackerId: UUID) -> Bool {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        return completedTrackers.contains(TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate))
    }
    
    private func completeTracker(_ trackerId: UUID) {
        let calendar = Calendar.current
        let selectedDate = datePicker.date
        let today = Date()
        
        let normalizedSelectedDate = calendar.startOfDay(for: selectedDate)
        let normalizedToday = calendar.startOfDay(for: today)
        
        guard normalizedSelectedDate <= normalizedToday else { return }
        
        let record = TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate)
        completedTrackers.insert(record)
        saveData()
        
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
        completedTrackers.remove(TrackerRecord(trackerId: trackerId, date: normalizedSelectedDate))
        saveData()
        
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
        let storage = DataStorageService.shared
        let savedCategories = storage.loadCategories()
        let savedCompletedTrackers = storage.loadCompletedTrackers()
        
        if savedCategories.isEmpty {
            // Если нет сохраненных данных, создаем начальную категорию
            categories = [
                TrackerCategory(title: "категория тест", trackers: [])
            ]
        } else {
            categories = savedCategories
        }
        
        completedTrackers = savedCompletedTrackers
    }
    
    @objc private func saveData() {
        let storage = DataStorageService.shared
        storage.saveCategories(categories)
        storage.saveCompletedTrackers(completedTrackers)
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
        let availableWidth = collectionView.frame.width - 9
        let cellWidth = availableWidth / 2
        return CGSize(width: cellWidth, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 46)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
    }
}

// MARK: - UISearchBarDelegate
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Реализация поиска будет добавлена позже
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        refreshData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension TrackersViewController: CreateTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, categoryTitle: String) {
        var newCategories = categories
        if let index = newCategories.firstIndex(where: { $0.title == categoryTitle }) {
            var updatedTrackers = newCategories[index].trackers
            updatedTrackers.append(tracker)
            newCategories[index] = TrackerCategory(title: categoryTitle, trackers: updatedTrackers)
        } else {
            let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
            newCategories.append(newCategory)
        }
        categories = newCategories
        saveData()
        
        print("📝 Added tracker: \(tracker.title)")
        print("📝 Schedule: \(tracker.schedule.map { $0.displayName })")
        print("📝 Total categories: \(categories.count)")
        print("📝 Total trackers in category '\(categoryTitle)': \(categories.first(where: { $0.title == categoryTitle })?.trackers.count ?? 0)")
        
        refreshData()
        
        dismiss(animated: true)
    }
}

