import UIKit

final class EmojiCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    private let emojiLabel = UILabel()
    
    // MARK: - Properties
    static let identifier = "EmojiCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.clear
        
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        emojiLabel.textAlignment = .center
        emojiLabel.textColor = .black
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 52),
            emojiLabel.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        
        if isSelected {
            // background: #E6E8EB, border-radius: 16px
            contentView.backgroundColor = UIColor(red: 230/255, green: 232/255, blue: 235/255, alpha: 1.0)
            contentView.layer.cornerRadius = 16
        } else {
            contentView.backgroundColor = UIColor.clear
            contentView.layer.cornerRadius = 0
        }
    }
}
