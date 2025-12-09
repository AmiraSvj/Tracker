import UIKit

final class CreateHabitScreen: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: CreateTrackerViewControllerDelegate?
    private var selectedCategory: String?
    private var selectedSchedule: [Weekday] = []
    
    // Constraints для адаптации позиции таблицы при появлении ошибки
    private var messageHeightConstraint: NSLayoutConstraint?
    private var optionsTopConstraint: NSLayoutConstraint?
    
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
        label.text = "Новая привычка"
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
        label.attributedText = NSAttributedString(string: "Новая привычка", attributes: attributes)
        
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
        button.setTitle("Создать", for: .normal)
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCreateButtonState()
        updatePlaceholderVisibility()
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
        
        view.addSubview(nameScreen)
        view.addSubview(textFieldContainer)
        textFieldContainer.addSubview(textField)
        textFieldContainer.addSubview(placeholderLabel)
        textFieldContainer.addSubview(clearTextButton)
        textFieldContainer.addSubview(errorLabel)
        view.addSubview(optionsTableView)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
        
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
            
            nameScreen.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameScreen.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            nameScreen.heightAnchor.constraint(equalToConstant: 22),
            
            // Контейнер для текстового поля: позиционируется относительно заголовка, высота 75px как в примере
            textFieldContainer.topAnchor.constraint(equalTo: nameScreen.bottomAnchor, constant: 38),
            textFieldContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textFieldContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
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
            optionsTableView.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor),
            optionsTableView.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
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
              let category = selectedCategory,
              !selectedSchedule.isEmpty else {
            print("Не все поля заполнены")
            return
        }
        
        let newTracker = Tracker(
            identifier: UUID(),
            title: name,
            color: .systemBlue,
            schedule: selectedSchedule,
            emoji: "😪"
        )
        delegate?.didCreateTracker(newTracker, categoryTitle: category)
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
        let isCategorySelected = selectedCategory != nil
        let isScheduleSelected = !selectedSchedule.isEmpty
        
        let isReadyToCreate = !isNameEmpty && isCategorySelected && isScheduleSelected
        
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
            let categoryVC = CategoryScreen()
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
        
        if indexPath.row == 0, let category = selectedCategory {
            cell.detailTextLabel?.text = category
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 17)
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

#Preview {
    CreateHabitScreen()
}

