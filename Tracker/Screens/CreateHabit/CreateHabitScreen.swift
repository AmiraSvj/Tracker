import UIKit

final class CreateHabitScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    private var selectedEmoji: String?
    private var selectedColorIndex: Int?
    
    // Режим редактирования
    private var editingTracker: Tracker?
    private var editingCategoryTitle: String?
    
    // Constraints для адаптации позиции таблицы при появлении ошибки
    private var messageHeightConstraint: NSLayoutConstraint?
    private var optionsTopConstraint: NSLayoutConstraint?
    
    // MARK: - Data
    
    private let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝️", "😪"
    ]
    
    private let colors: [UIColor] = [
        UIColor(red: 253/255, green: 76/255, blue: 73/255, alpha: 1),    // Красный
        UIColor(red: 255/255, green: 136/255, blue: 30/255, alpha: 1),   // Оранжевый
        UIColor(red: 0/255, green: 121/255, blue: 255/255, alpha: 1),    // Синий
        UIColor(red: 52/255, green: 211/255, blue: 103/255, alpha: 1),   // Зеленый
        UIColor(red: 234/255, green: 0/255, blue: 255/255, alpha: 1),    // Фиолетовый
        UIColor(red: 255/255, green: 119/255, blue: 255/255, alpha: 1),  // Розовый
        UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1),   // Светло-зеленый
        UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1),   // Голубой
        UIColor(red: 255/255, green: 204/255, blue: 0/255, alpha: 1),    // Желтый
        UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1),    // Оранжево-желтый
        UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1),    // Розово-красный
        UIColor(red: 175/255, green: 82/255, blue: 222/255, alpha: 1),  // Фиолетовый
        UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1),   // Красный
        UIColor(red: 255/255, green: 159/255, blue: 10/255, alpha: 1),  // Оранжевый
        UIColor(red: 0/255, green: 199/255, blue: 190/255, alpha: 1),   // Бирюзовый
        UIColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1),  // Зеленый
        UIColor(red: 64/255, green: 156/255, blue: 255/255, alpha: 1),  // Синий
        UIColor(red: 191/255, green: 90/255, blue: 242/255, alpha: 1)   // Фиолетовый
    ]
    
    // MARK: - UI Elements
    
    private lazy var textFieldContainer: UIView = {
        let container = UIView()
        container.layer.cornerRadius = 16
        container.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private lazy var nameScreen: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        
        // Настройка line-height согласно макету
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        
        let title = editingTracker != nil ? "Редактирование привычки" : "Новая привычка"
        label.attributedText = NSAttributedString(string: title, attributes: attributes)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textField: UITextView = {
        let textView = UITextView()
        textView.text = ""
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        // Вертикальное центрирование: первая строка по центру контейнера (75px)
        // Высота строки ~22px, контейнер 75px
        // Для одной строки по центру: top = (75 - 22) / 2 = 26.5px
        // При появлении второй строки она будет ниже первой
        textView.textContainerInset = UIEdgeInsets(top: 26.5, left: 16, bottom: 5, right: 50)
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.textContainer.maximumNumberOfLines = 2
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.heightTracksTextView = true
        textView.textColor = .black
        textView.textAlignment = .left
        // Отключаем автоматическую корректировку контента
        textView.contentInsetAdjustmentBehavior = .never
        textView.layoutManager.usesFontLeading = false
        
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Введите название трекера"
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var clearTextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .yGray
        button.alpha = 0
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    } ()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.alpha = 0
        
        // Настройка текста с точными параметрами из макета
        let text = "Ограничение 38 символов"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor(red: 245/255, green: 107/255, blue: 108/255, alpha: 1), // #F56B6C
            .paragraphStyle: paragraphStyle
        ]
        
        label.attributedText = NSAttributedString(string: text, attributes: attributes)
        
        return label
    } ()
    
    private lazy var optionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.layer.cornerRadius = 16
        tableView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.yRed, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.yRed.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated:true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        let title = editingTracker != nil ? "Сохранить" : "Создать"
        button.setTitle(title, for: .normal)
        button.backgroundColor = .yGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.createTracker()
        }, for: .touchUpInside)
        
        return button
    }()
    
    private let options = ["Категория", "Расписание"]
    
    // MARK: - Scroll View
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Emoji and Color Collections
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Emoji"
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.sectionInset = UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 19)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: EmojiCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Цвет"
        label.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: 52, height: 52)
        layout.sectionInset = UIEdgeInsets(top: 24, left: 18, bottom: 24, right: 19)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: ColorCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    // MARK: - Initialization
    
    init(editingTracker: Tracker? = nil, categoryTitle: String? = nil) {
        self.editingTracker = editingTracker
        self.editingCategoryTitle = categoryTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let tracker = editingTracker {
            loadTrackerData(tracker)
            // Обновляем текст кнопки после загрузки данных
            let title = editingTracker != nil ? "Сохранить" : "Создать"
            createButton.setTitle(title, for: .normal)
        }
        updateCreateButtonState()
        updatePlaceholderVisibility()
    }
    
    // MARK: - Private Methods
    
    private func loadTrackerData(_ tracker: Tracker) {
        // Предзаполняем поля данными трекера
        textField.text = tracker.title
        selectedSchedule = tracker.schedule
        selectedEmoji = tracker.emoji
        selectedCategory = editingCategoryTitle
        
        // Находим индекс цвета
        if let colorIndex = colors.firstIndex(where: { color in
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            tracker.color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 && abs(a1 - a2) < 0.01
        }) {
            selectedColorIndex = colorIndex
        }
        
        // Обновляем UI
        optionsTableView.reloadData()
        emojiCollectionView.reloadData()
        colorCollectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Принудительно сбрасываем contentOffset после layout чтобы текст всегда был виден
        textField.contentOffset = .zero
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        
        view.backgroundColor = .white
        
        textField.delegate = self
        
        // Добавляем ScrollView и contentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Кнопки остаются в view (зафиксированы внизу)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
        // Весь контент добавляется в contentView
        contentView.addSubview(nameScreen)
        contentView.addSubview(textFieldContainer)
        textFieldContainer.addSubview(textField)
        textFieldContainer.addSubview(placeholderLabel)
        textFieldContainer.addSubview(clearTextButton)
        textFieldContainer.addSubview(errorLabel)
        contentView.addSubview(optionsTableView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiCollectionView)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorCollectionView)
        
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextViewChange),
            name: UITextView.textDidChangeNotification,
            object: textField
        )
        
        clearTextButton.addAction(UIAction { [weak self] _ in
            self?.clearTextField()
        }, for: .touchUpInside)
        
        setupConstraints()
        
    }
    
    private func setupConstraints() {
        
        // Высота сообщения об ошибке (динамически меняется)
        messageHeightConstraint = errorLabel.heightAnchor.constraint(equalToConstant: 0)
        messageHeightConstraint?.isActive = true
        
        // Позиция таблицы относительно ошибки (динамически меняется)
        optionsTopConstraint = optionsTableView.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: 32)
        optionsTopConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            // ScrollView занимает пространство между верхом и кнопками
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            
            // contentView внутри ScrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            nameScreen.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameScreen.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 27),
            nameScreen.heightAnchor.constraint(equalToConstant: 22),
            
            // Контейнер для текстового поля: позиционируется относительно заголовка, высота 75px как в примере
            textFieldContainer.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 38),
            textFieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textFieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 75),
            
            // UITextView занимает всю высоту контейнера
            textField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            textField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            
            // Placeholder на уровне первой строки текста (на уровне крестика)
            placeholderLabel.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -50),
            
            // Кнопка очистки по центру контейнера по вертикали
            clearTextButton.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            clearTextButton.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -16),
            clearTextButton.widthAnchor.constraint(equalToConstant: 17),
            clearTextButton.heightAnchor.constraint(equalToConstant: 17),
            
            // Ошибка позиционируется относительно контейнера (как в примере)
            errorLabel.centerXAnchor.constraint(equalTo: textFieldContainer.centerXAnchor),
            errorLabel.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: 8),
            errorLabel.widthAnchor.constraint(equalToConstant: 286),
            
            // Таблица позиционируется относительно ошибки
            optionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
            // Emoji section
            emojiLabel.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: 32),
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            emojiLabel.widthAnchor.constraint(equalToConstant: 52),
            emojiLabel.heightAnchor.constraint(equalToConstant: 18),
            
            emojiCollectionView.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            // Color section
            colorLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 16),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            colorLabel.widthAnchor.constraint(equalToConstant: 52),
            colorLabel.heightAnchor.constraint(equalToConstant: 18),
            
            colorCollectionView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 204),
            colorCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -4),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            
            createButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 4),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    private func createTracker() {
        guard let name = textField.text, !name.isEmpty,
              !selectedSchedule.isEmpty,
              let emoji = selectedEmoji,
              let colorIndex = selectedColorIndex else {
            print("Не все поля заполнены")
            return
        }
        
        // Категория должна быть выбрана перед созданием трекера
        guard let category = selectedCategory else {
            let alert = UIAlertController(
                title: "Ошибка",
                message: "Пожалуйста, выберите категорию",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let color = colors[colorIndex]
        
        if let editingTracker = editingTracker {
            // Режим редактирования - обновляем трекер
            let updatedTracker = Tracker(
                identifier: editingTracker.identifier,
                title: name,
                color: color,
                schedule: selectedSchedule,
                emoji: emoji,
                isPinned: editingTracker.isPinned
            )
            delegate?.didUpdateTracker(updatedTracker, categoryTitle: category)
        } else {
            // Режим создания - создаем новый трекер
            let newTracker = Tracker(
                identifier: UUID(),
                title: name,
                color: color,
                schedule: selectedSchedule,
                emoji: emoji,
                isPinned: false
            )
            delegate?.didCreateTracker(newTracker, categoryTitle: category)
        }
        
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc private func handleTextViewChange() {
        // Важно: сбрасываем contentOffset чтобы текст всегда был виден
        textField.contentOffset = .zero
        updatePlaceholderVisibility()
        updateCreateButtonState()
        updateClearButtonVisibility()
        validateTextLength()
    }
    
    private func handleTextFieldChange() {
        updatePlaceholderVisibility()
        updateCreateButtonState()
        updateClearButtonVisibility()
        validateTextLength()
    }
    
    private func clearTextField() {
        textField.text = ""
        handleTextFieldChange()
        textField.becomeFirstResponder()
    }
    
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textField.text?.isEmpty ?? true)
    }
    
    private func updateClearButtonVisibility() {
        let hasText = !(textField.text?.isEmpty ?? true)
        UIView.animate(withDuration: 0.2) {
            self.clearTextButton.alpha = hasText ? 1 : 0
        }
    }
    
    private func validateTextLength() {
        guard let text = textField.text else { return }
        if text.count >= 38 {
            let index = text.index(text.startIndex, offsetBy: 38)
            textField.text = String(text[..<index])
            
            // Показываем ошибку и меняем constraints: опускаем таблицу на 38px вниз
            messageHeightConstraint?.constant = 22
            optionsTopConstraint?.constant = 32 + 38  // 70px от textFieldContainer.bottomAnchor
            
            UIView.animate(withDuration: 0.3) {
                self.errorLabel.alpha = 1
                self.view.layoutIfNeeded()
            }
        } else {
            // Скрываем ошибку и меняем constraints (как в примере)
            messageHeightConstraint?.constant = 0
            optionsTopConstraint?.constant = 32
            
            UIView.animate(withDuration: 0.3) {
                self.errorLabel.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func updateCreateButtonState() {
        let isNameEmpty = textField.text?.isEmpty ?? true
        let isScheduleSelected = !selectedSchedule.isEmpty
        let isEmojiSelected = selectedEmoji != nil
        let isColorSelected = selectedColorIndex != nil
        
        // Категория больше не обязательна - используется заглушка по умолчанию
        let isReadyToCreate = !isNameEmpty && isScheduleSelected && isEmojiSelected && isColorSelected
        
        createButton.isEnabled = isReadyToCreate
        createButton.backgroundColor = isReadyToCreate ? .black : .gray
    }
}

// MARK: - UITableViewDelegate

extension CreateHabitScreen: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            // Переход на экран выбора категории
            let categoryVC = CategoryScreen(selectedCategoryTitle: selectedCategory)
            categoryVC.delegate = self
            let navController = UINavigationController(rootViewController: categoryVC)
            present(navController, animated: true)
        case 1:
            let scheduleVC = SheduleScreen()
            scheduleVC.delegate = self
            scheduleVC.selectedDays = selectedSchedule
            let navController = UINavigationController(rootViewController: scheduleVC)
            present(navController, animated: true)
        default:
            break
        }
    }
    
    private func formatScheduleText(_ schedule: [Weekday]) -> String {
        if schedule.count == Weekday.allCases.count {
            return "Каждый день"
        } else {
            let sortedSchedule = schedule.sorted { $0.rawValue < $1.rawValue }
            return sortedSchedule.map { $0.abbreviatedName }.joined(separator: ", ")
        }
    }
}

// MARK: - UITableViewDataSource

extension CreateHabitScreen: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = options[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        cell.textLabel?.textColor = .yBlackDay
        
        if indexPath.row == 0 {
            // Показываем выбранную категорию только если она выбрана, иначе только заголовок
            if let category = selectedCategory {
                cell.detailTextLabel?.text = category
                cell.detailTextLabel?.textColor = .gray
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17)
            } else {
                cell.detailTextLabel?.text = nil
            }
        } else if indexPath.row == 1, !selectedSchedule.isEmpty {
            let scheduleText = formatScheduleText(selectedSchedule)
            cell.detailTextLabel?.text = scheduleText
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17)
        } else {
            cell.detailTextLabel?.text = nil
        }
        
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.row == 0 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: .greatestFiniteMagnitude)
        }
        
        cell.backgroundColor = .clear
        
        return cell
    }
}

// MARK: - Delegate Methods

extension CreateHabitScreen: CategorySelectionDelegate {
    func didSelectCategory(_ category: String) {
        selectedCategory = category
        optionsTableView.reloadData()
        updateCreateButtonState()
    }
}

extension CreateHabitScreen: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: [Weekday]) {
        selectedSchedule = schedule
        optionsTableView.reloadData()
        updateCreateButtonState()
    }
}

extension CreateHabitScreen: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Важно: принудительно сбрасываем contentOffset чтобы текст всегда был виден
        DispatchQueue.main.async { [weak self] in
            self?.textField.contentOffset = .zero
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // При начале редактирования также сбрасываем offset
        DispatchQueue.main.async { [weak self] in
            self?.textField.contentOffset = .zero
        }
    }
    
}

// MARK: - UICollectionViewDataSource

extension CreateHabitScreen: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return emojis.count
        } else if collectionView == colorCollectionView {
            return colors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.identifier, for: indexPath) as? EmojiCollectionViewCell else {
                return UICollectionViewCell()
            }
            let emoji = emojis[indexPath.item]
            let isSelected = emoji == selectedEmoji
            cell.configure(with: emoji, isSelected: isSelected)
            return cell
        } else if collectionView == colorCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCollectionViewCell.identifier, for: indexPath) as? ColorCollectionViewCell else {
                return UICollectionViewCell()
            }
            let color = colors[indexPath.item]
            let isSelected = indexPath.item == selectedColorIndex
            cell.configure(with: color, isSelected: isSelected)
            return cell
        }
        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegate

extension CreateHabitScreen: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            selectedEmoji = emojis[indexPath.item]
            emojiCollectionView.reloadData()
            updateCreateButtonState()
        } else if collectionView == colorCollectionView {
            selectedColorIndex = indexPath.item
            colorCollectionView.reloadData()
            updateCreateButtonState()
        }
    }
}

#Preview {
    CreateHabitScreen()
}

