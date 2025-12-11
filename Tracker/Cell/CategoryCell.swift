import UIKit

final class CategoryCell: UITableViewCell {
    
    static let identifier = "CategoryCell"
    
    // MARK: - Properties
    var onLongPress: ((TrackerCategory) -> Void)?
    private var category: TrackerCategory?
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor(red: 0/255, green: 121/255, blue: 255/255, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear // Как в расписании - прозрачный фон ячейки
        containerView.layer.cornerRadius = 0
        contentView.addSubview(containerView)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        containerView.addGestureRecognizer(longPressGesture)
        
        containerView.addSubview(titleLabel)
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
    
    // MARK: - Configuration
    func configure(with category: TrackerCategory, isSelected: Bool) {
        titleLabel.text = category.title
        checkmarkImageView.isHidden = !isSelected
        self.category = category
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        checkmarkImageView.isHidden = true
        category = nil
    }
    
    // MARK: - Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let category = category else { return }
            onLongPress?(category)
        }
    }
}
