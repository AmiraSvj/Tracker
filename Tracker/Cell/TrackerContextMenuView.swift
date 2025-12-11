import UIKit

protocol TrackerContextMenuViewDelegate: AnyObject {
    func didTapEditTracker(_ tracker: Tracker)
    func didTapDeleteTracker(_ tracker: Tracker)
    func didTapPinTracker(_ tracker: Tracker)
}

final class TrackerContextMenuView: UIView {

    // MARK: - UI Elements
    private let containerView = UIView()
    private let editButton = UIButton(type: .system)
    private let pinButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let separatorView1 = UIView()
    private let separatorView2 = UIView()

    // MARK: - Properties
    weak var delegate: TrackerContextMenuViewDelegate?
    private var tracker: Tracker?

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
        // Делаем фон полностью непрозрачным белым, чтобы перекрыть элементы под меню (адаптивный)
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 13
        clipsToBounds = true

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 0.3)
        containerView.layer.cornerRadius = 13
        containerView.clipsToBounds = true
        addSubview(containerView)

        pinButton.translatesAutoresizingMaskIntoConstraints = false
        pinButton.setTitle(NSLocalizedString("Pin", comment: "Pin button"), for: .normal)
        pinButton.setTitleColor(UIColor(named: "yBlackDay") ?? .label, for: .normal)
        pinButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        pinButton.backgroundColor = UIColor.clear
        pinButton.contentHorizontalAlignment = .left
        pinButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        pinButton.addTarget(self, action: #selector(pinButtonTapped), for: .touchUpInside)
        containerView.addSubview(pinButton)

        separatorView1.translatesAutoresizingMaskIntoConstraints = false
        separatorView1.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 0.3)
        containerView.addSubview(separatorView1)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle(NSLocalizedString("Edit", comment: "Edit button"), for: .normal)
        editButton.setTitleColor(UIColor(named: "yBlackDay") ?? .label, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        editButton.backgroundColor = UIColor.clear
        editButton.contentHorizontalAlignment = .left
        editButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        containerView.addSubview(editButton)

        separatorView2.translatesAutoresizingMaskIntoConstraints = false
        separatorView2.backgroundColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 0.3)
        containerView.addSubview(separatorView2)

        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setTitle(NSLocalizedString("Delete", comment: "Delete button"), for: .normal)
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
            containerView.heightAnchor.constraint(equalToConstant: 145.5), // 48.5 * 3 = 145.5

            pinButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            pinButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pinButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pinButton.heightAnchor.constraint(equalToConstant: 48.5),

            separatorView1.topAnchor.constraint(equalTo: pinButton.bottomAnchor),
            separatorView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView1.heightAnchor.constraint(equalToConstant: 0.5),

            editButton.topAnchor.constraint(equalTo: separatorView1.bottomAnchor),
            editButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 48.5),

            separatorView2.topAnchor.constraint(equalTo: editButton.bottomAnchor),
            separatorView2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView2.heightAnchor.constraint(equalToConstant: 0.5),

            deleteButton.topAnchor.constraint(equalTo: separatorView2.bottomAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Configuration
    func configure(with tracker: Tracker) {
        self.tracker = tracker
        // Обновляем текст кнопки в зависимости от состояния закрепления
        if tracker.isPinned {
            pinButton.setTitle(NSLocalizedString("Unpin", comment: "Unpin button"), for: .normal)
        } else {
            pinButton.setTitle(NSLocalizedString("Pin", comment: "Pin button"), for: .normal)
        }
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        guard let tracker = tracker else { return }
        delegate?.didTapEditTracker(tracker)
    }

    @objc private func pinButtonTapped() {
        guard let tracker = tracker else { return }
        delegate?.didTapPinTracker(tracker)
    }

    @objc private func deleteButtonTapped() {
        guard let tracker = tracker else { return }
        delegate?.didTapDeleteTracker(tracker)
    }
}
