import UIKit

final class ColorCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    private let colorView = UIView()
    private let borderView = UIView()
    
    // MARK: - Properties
    static let identifier = "ColorCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.clear
        
        // Цветной квадрат
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.layer.cornerRadius = 8
        contentView.addSubview(colorView)
        
        // Обводка для выделения (скрыта по умолчанию)
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = .clear
        borderView.layer.cornerRadius = 12 // Больше скругление углов
        borderView.isHidden = true
        contentView.addSubview(borderView)
        
        NSLayoutConstraint.activate([
            // Цветной квадрат 40x40 по центру
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40),
            
            // Обводка: промежуток между обводкой и цветом = толщине обводки (3px)
            // Цветной квадрат 40x40, промежуток 3px с каждой стороны = внутренний размер 46x46
            // Border 3px с каждой стороны = внешний размер 52x52
            borderView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            borderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            borderView.widthAnchor.constraint(equalToConstant: 52),
            borderView.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    func configure(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        
        if isSelected {
            // border: 3px solid цвет с opacity 0.3, border-radius: 12px (больше скругление)
            borderView.isHidden = false
            borderView.layer.borderWidth = 3
            borderView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            borderView.isHidden = true
            borderView.layer.borderWidth = 0
        }
    }
}
