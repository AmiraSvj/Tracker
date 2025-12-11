import UIKit

protocol CategoryContextMenuViewDelegate: AnyObject {
    func didTapEditCategory(_ category: TrackerCategory)
    func didTapDeleteCategory(_ category: TrackerCategory)
}

final class CategoryContextMenuView: UIView {

    // MARK: - UI Elements
    private let containerView = UIView()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let separatorView = UIView()

    // MARK: - Properties
    weak var delegate: CategoryContextMenuViewDelegate?
    private var category: TrackerCategory?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        // Делаем фон полностью непрозрачным белым, чтобы перекрыть элементы под меню
        backgroundColor = UIColor.white
        layer.cornerRadius = 13
        clipsToBounds = true

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        containerView.layer.cornerRadius = 13
        addSubview(containerView)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle("Редактировать", for: .normal)
        editButton.setTitleColor(.black, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editButton.backgroundColor = UIColor.clear
        editButton.contentHorizontalAlignment = .left
        editButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        containerView.addSubview(editButton)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 0.3)
        containerView.addSubview(separatorView)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.setTitleColor(UIColor(red: 245/255, green: 107/255, blue: 108/255, alpha: 1), for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        deleteButton.backgroundColor = UIColor.clear
        deleteButton.contentHorizontalAlignment = .left
        deleteButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        containerView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 250),
            containerView.heightAnchor.constraint(equalToConstant: 97),

            editButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            editButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 48.5),

            separatorView.topAnchor.constraint(equalTo: editButton.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            deleteButton.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Configuration
    func configure(with category: TrackerCategory) {
        self.category = category
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        guard let category = category else { return }
        delegate?.didTapEditCategory(category)
    }

    @objc private func deleteButtonTapped() {
        guard let category = category else { return }
        delegate?.didTapDeleteCategory(category)
    }
}
