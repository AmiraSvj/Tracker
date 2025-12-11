import UIKit

final class TrackerCell: UICollectionViewCell {
    
    // MARK: - Helper Methods для адаптации размеров
    
    /// Вычисляет адаптированный размер иконки плюса в зависимости от размера экрана
    private static func adaptedPlusIconSize() -> (width: CGFloat, height: CGFloat, pointSize: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        let baseWidth: CGFloat = 10.625
        let baseHeight: CGFloat = 10.206705093383789
        
        // Адаптация под разные размеры экранов для хорошей видимости плюса
        // Увеличиваем размер для лучшей видимости, сохраняя пропорции макета
        let scaleFactor: CGFloat
        if screenWidth <= 375 {
            // Маленькие экраны (iPhone SE) - увеличенный размер для видимости
            scaleFactor = 1.3
        } else if screenWidth <= 390 {
            // Средние экраны (iPhone 14/15) - еще больше
            scaleFactor = 1.4
        } else {
            // Большие экраны (iPhone 14/15 Pro Max) - максимальный размер
            scaleFactor = 1.5
        }
        
        let width = baseWidth * scaleFactor
        let height = baseHeight * scaleFactor
        // pointSize используем максимальный размер для правильного отображения
        let pointSize = max(width, height)
        
        return (width: width, height: height, pointSize: pointSize)
    }
    
    /// Вычисляет адаптированное позиционирование иконки согласно макету
    private static func adaptedPlusIconPosition() -> (top: CGFloat, left: CGFloat) {
        let baseTop: CGFloat = 11.72
        let baseLeft: CGFloat = 11.72
        
        // Адаптируем позицию для центрирования увеличенной иконки
        let screenWidth = UIScreen.main.bounds.width
        let (iconWidth, iconHeight, _) = adaptedPlusIconSize()
        let buttonSize: CGFloat = 34
        
        // Центрируем иконку в кнопке с учетом увеличенного размера
        // Вычисляем отступы для центрирования
        let top = (buttonSize - iconHeight) / 2
        let left = (buttonSize - iconWidth) / 2
        
        return (top: top, left: left)
    }
    
    /// Вычисляет адаптированный размер иконки галочки в зависимости от размера экрана
    private static func adaptedCheckmarkIconSize() -> (width: CGFloat, height: CGFloat, pointSize: CGFloat) {
        let screenWidth = UIScreen.main.bounds.width
        let baseWidth: CGFloat = 12
        let baseHeight: CGFloat = 12
        
        // Адаптация под разные размеры экранов для хорошей видимости галочки
        // Умеренное увеличение размера для видимости
        let scaleFactor: CGFloat
        if screenWidth <= 375 {
            // Маленькие экраны (iPhone SE) - умеренный размер
            scaleFactor = 1.25
        } else if screenWidth <= 390 {
            // Средние экраны (iPhone 14/15)
            scaleFactor = 1.3
        } else {
            // Большие экраны (iPhone 14/15 Pro Max)
            scaleFactor = 1.35
        }
        
        let width = baseWidth * scaleFactor
        let height = baseHeight * scaleFactor
        // pointSize используем максимальный размер для правильного отображения
        let pointSize = max(width, height)
        
        return (width: width, height: height, pointSize: pointSize)
    }
    
    /// Вычисляет адаптированное позиционирование галочки согласно макету
    private static func adaptedCheckmarkIconPosition() -> (top: CGFloat, left: CGFloat) {
        let baseTop: CGFloat = 11
        let baseLeft: CGFloat = 11
        
        // Адаптируем позицию для центрирования увеличенной иконки
        let (iconWidth, iconHeight, _) = adaptedCheckmarkIconSize()
        let buttonSize: CGFloat = 34
        
        // Центрируем иконку в кнопке с учетом увеличенного размера
        let top = (buttonSize - iconHeight) / 2
        let left = (buttonSize - iconWidth) / 2
        
        return (top: top, left: left)
    }
    
    // MARK: UI Elements
    
    private lazy var colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        // Border: 1px solid #AEAFB44D
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 0.3).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        // Font: SF Pro Medium, 14px (уменьшенный размер), text-align: center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        // Background: #FFFFFF4D, border-radius: 12px (круглый для 24x24)
        label.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        label.layer.cornerRadius = 12 // Для круглой формы 24x24
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        // Font: SF Pro Medium, 12px, line-height: 18px, color: #FFFFFF
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        // Настройка line-height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.maximumLineHeight = 18
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var pinImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        imageView.image = UIImage(systemName: "pin.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var daysLabel: UILabel = {
        let label = UILabel()
        // Font: SF Pro Medium, 12px, line-height: 18px, color: #1A1B22 (адаптивный)
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(named: "yBlackDay") ?? .label
        // Настройка line-height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.maximumLineHeight = 18
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var completeButton: UIButton = {
        let button = UIButton(type: .custom)
        // Button 34x34: border-radius для круглой кнопки
        button.layer.cornerRadius = 17 // 34/2 = 17
        button.clipsToBounds = true
        // Border-width: 1px
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(UIAction { [weak self] _ in
            self?.onCompleteButtonTapped?()
        }, for: .touchUpInside)
        
        return button
    }()
    
    // Отдельный UIImageView для иконки плюса для точного позиционирования
    private lazy var plusIconView: UIImageView = {
        let imageView = UIImageView()
        // Адаптируем размер иконки под экран
        let (_, _, pointSize) = Self.adaptedPlusIconSize()
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        imageView.image = UIImage(systemName: "plus", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Отдельный UIImageView для иконки галочки для точного позиционирования
    private lazy var checkmarkIconView: UIImageView = {
        let imageView = UIImageView()
        // Checkmark: width: 12, height: 12 (адаптировано), color: #FFFFFF, weight: heavy для очень толстой линии
        let (_, _, pointSize) = Self.adaptedCheckmarkIconSize()
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .heavy)
        imageView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        imageView.tintColor = .white // #FFFFFF
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Properties
    
    var onCompleteButtonTapped: (() -> Void)?
    var onLongPress: ((Tracker) -> Void)?
    private var trackerId: UUID?
    private var tracker: Tracker?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Card + Quantity management: background: #FFFFFF (адаптивный)
        contentView.backgroundColor = UIColor.systemBackground
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        contentView.addSubview(colorView)
        colorView.addSubview(emojiLabel)
        colorView.addSubview(nameLabel)
        colorView.addSubview(pinImageView)
        contentView.addSubview(daysLabel)
        contentView.addSubview(completeButton)
        completeButton.addSubview(plusIconView)
        completeButton.addSubview(checkmarkIconView)
        
        // Добавляем long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        contentView.addGestureRecognizer(longPressGesture)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Card/Tracker: width: 167, height: 90
            colorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            colorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            colorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            colorView.heightAnchor.constraint(equalToConstant: 90),
            
            // ic 24x24: top: 12px, left: 12px
            // Контейнер эмодзи: 24x24
            emojiLabel.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            
            // Text: width: 143, top: 44px, left: 12px (bottom: 90 - 44 - 12 = 34px от низа, но используем bottom)
            nameLabel.leadingAnchor.constraint(equalTo: colorView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -28), // Оставляем место для иконки заклепки
            nameLabel.bottomAnchor.constraint(equalTo: colorView.bottomAnchor, constant: -12),
            
            // Pin icon: 24x24, top: 12px, trailing: 12px
            pinImageView.topAnchor.constraint(equalTo: colorView.topAnchor, constant: 12),
            pinImageView.trailingAnchor.constraint(equalTo: colorView.trailingAnchor, constant: -12),
            pinImageView.widthAnchor.constraint(equalToConstant: 24),
            pinImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Quantity management text: width: 101, height: 18, top: 16px (от colorView.bottom), left: 12px
            daysLabel.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 16),
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.widthAnchor.constraint(equalToConstant: 101),
            daysLabel.heightAnchor.constraint(equalToConstant: 18),
            
            // Button 34x34: top: 8px (от colorView.bottom), left: 121px (trailing: 167 - 121 - 34 = 12px)
            completeButton.topAnchor.constraint(equalTo: colorView.bottomAnchor, constant: 8),
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34),
            
            // Plus icon: width: 10.625, height: 10.206705093383789 (адаптировано)
            // Position: top: 11.72px, left: 11.72px (адаптировано)
            plusIconView.topAnchor.constraint(equalTo: completeButton.topAnchor, constant: Self.adaptedPlusIconPosition().top),
            plusIconView.leadingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: Self.adaptedPlusIconPosition().left),
            plusIconView.widthAnchor.constraint(equalToConstant: Self.adaptedPlusIconSize().width),
            plusIconView.heightAnchor.constraint(equalToConstant: Self.adaptedPlusIconSize().height),
            
            // Checkmark icon: width: 12, height: 12 (адаптировано)
            // Position: top: 11px, left: 11px (адаптировано)
            checkmarkIconView.topAnchor.constraint(equalTo: completeButton.topAnchor, constant: Self.adaptedCheckmarkIconPosition().top),
            checkmarkIconView.leadingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: Self.adaptedCheckmarkIconPosition().left),
            checkmarkIconView.widthAnchor.constraint(equalToConstant: Self.adaptedCheckmarkIconSize().width),
            checkmarkIconView.heightAnchor.constraint(equalToConstant: Self.adaptedCheckmarkIconSize().height)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with tracker: Tracker, completedDays: Int, isCompletedToday: Bool) {
        self.tracker = tracker
        trackerId = tracker.identifier
        // Используем цвет из трекера для карточки
        colorView.backgroundColor = tracker.color
        
        // Показываем иконку заклепки, если трекер закреплен
        pinImageView.isHidden = !tracker.isPinned
        // Card + Quantity management background: #FFFFFF (устанавливается в init)
        
        // Устанавливаем эмодзи напрямую (эмодзи отображаются правильно)
        emojiLabel.text = tracker.emoji
        
        // Настройка attributed text для nameLabel с правильным line-height
        let nameParagraphStyle = NSMutableParagraphStyle()
        nameParagraphStyle.minimumLineHeight = 18
        nameParagraphStyle.maximumLineHeight = 18
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: nameParagraphStyle
        ]
        nameLabel.attributedText = NSAttributedString(string: tracker.title, attributes: nameAttributes)
        
        let dayString = formatDays(count: completedDays)
        // Настройка attributed text для daysLabel с правильным line-height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.maximumLineHeight = 18
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor(named: "yBlackDay") ?? .label,
            .paragraphStyle: paragraphStyle
        ]
        daysLabel.attributedText = NSAttributedString(string: dayString, attributes: attributes)
        
        updateCompleteButton(isCompletedToday: isCompletedToday, color: tracker.color)
    }
    
    func updateCompleteButton(isCompletedToday: Bool, color: UIColor) {
        // Используем цвет трекера для кнопки
        
        // Полностью сбрасываем все параметры кнопки перед установкой нового состояния
        completeButton.setImage(nil, for: .normal)
        completeButton.imageEdgeInsets = .zero
        completeButton.contentEdgeInsets = .zero
        completeButton.titleEdgeInsets = .zero
        
        if isCompletedToday {
            // Состояние: выполнено - показываем checkmark
            // Button background: цвет трекера с opacity 30% (полупрозрачный)
            plusIconView.isHidden = true
            checkmarkIconView.isHidden = false
            
            // Обновляем размер галочки при изменении состояния
            let (_, _, pointSize) = Self.adaptedCheckmarkIconSize()
            let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .heavy)
            checkmarkIconView.image = UIImage(systemName: "checkmark", withConfiguration: config)
            
            completeButton.setImage(nil, for: .normal) // Убираем изображение с кнопки
            completeButton.backgroundColor = color.withAlphaComponent(0.3)
            completeButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            // Состояние: не выполнено - показываем плюс
            // Button 34x34: background: цвет трекера, plus icon: white (#FFFFFF)
            plusIconView.isHidden = false
            checkmarkIconView.isHidden = true
            completeButton.backgroundColor = color
            completeButton.tintColor = .white
            
            // Обновляем размер иконки при изменении состояния
            let (_, _, pointSize) = Self.adaptedPlusIconSize()
            let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
            plusIconView.image = UIImage(systemName: "plus", withConfiguration: config)
            
            // Border невидимый (прозрачный) - заливка до края
            completeButton.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func formatDays(count: Int) -> String {
        // Используем локализованное форматирование с учетом плюрализации
        let formatString: String
        
        // Для английского языка: 1 day, остальное days
        // Для русского языка: 1 день, 2-4 дня, 5+ дней
        let languageCode = Locale.current.languageCode ?? "en"
        
        if languageCode == "ru" {
            let remainder10 = count % 10
            let remainder100 = count % 100
            
            if remainder10 == 1 && remainder100 != 11 {
                formatString = NSLocalizedString("day", comment: "Singular day")
            } else if remainder10 >= 2 && remainder10 <= 4 && (remainder100 < 10 || remainder100 >= 20) {
                formatString = NSLocalizedString("day_plural", comment: "Plural day (2-4)")
            } else {
                formatString = NSLocalizedString("days", comment: "Plural days (5+)")
            }
        } else {
            // Английский и другие языки: простая плюрализация
            if count == 1 {
                formatString = NSLocalizedString("day", comment: "Singular day")
            } else {
                formatString = NSLocalizedString("days", comment: "Plural days")
            }
        }
        
        return "\(count) \(formatString)"
    }
    
    // MARK: - Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let tracker = tracker else { return }
            onLongPress?(tracker)
        }
    }
}

