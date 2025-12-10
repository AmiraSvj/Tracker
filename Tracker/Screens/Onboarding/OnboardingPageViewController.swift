//
//  OnboardingPageViewController.swift
//  Tracker
//
//  Created by Zhukov Konstantin on 05.11.2025.
//

import UIKit

final class OnboardingPageViewController: UIViewController {

    // MARK: - UI Elements
    private let backgroundImageView = UIImageView()
    private let titleLabel = UILabel()

    // MARK: - Properties
    let pageIndex: Int
    private let titleText: String
    private let backgroundImageName: String

    init(pageIndex: Int, titleText: String, backgroundImageName: String) {
        self.pageIndex = pageIndex
        self.titleText = titleText
        self.backgroundImageName = backgroundImageName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white

        setupBackgroundImage()
        setupTitleLabel()
    }

    private func setupBackgroundImage() {
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.image = UIImage(named: backgroundImageName)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = titleText
        
        // SF Pro Bold, font-weight: 700, font-size: 32px
        let font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.font = font
        titleLabel.textColor = UIColor(named: "BlackDay")
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.baselineAdjustment = .none  // vertical-align: bottom

        let paragraphStyle = NSMutableParagraphStyle()
        // Line height: 38px для font size 32px
        paragraphStyle.lineHeightMultiple = 38.0 / 32.0
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributedString = NSAttributedString(
            string: titleText,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: UIColor(named: "BlackDay") ?? UIColor.black,
                .kern: 0.0  // letter-spacing: 0px
            ]
        )
        titleLabel.attributedText = attributedString

        view.addSubview(titleLabel)

        // Адаптивные constraints для разных размеров экранов
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        // Базовые значения из дизайна Figma (375x812 - iPhone X/XS/11 Pro)
        let baseHeight: CGFloat = 812
        let baseWidth: CGFloat = 375
        let baseTopOffset: CGFloat = 432
        let baseLabelWidth: CGFloat = 343
        
        // Масштабируем отступ сверху пропорционально высоте экрана
        let topOffset = (screenHeight / baseHeight) * baseTopOffset
        
        // Адаптивная ширина: сохраняем пропорции относительно базовой ширины
        let labelWidth = min(baseLabelWidth * (screenWidth / baseWidth), screenWidth - 32)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset),
            titleLabel.widthAnchor.constraint(equalToConstant: labelWidth),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 76)
        ])
    }
    
    // MARK: - Equatable
    static func == (lhs: OnboardingPageViewController, rhs: OnboardingPageViewController) -> Bool {
        return lhs.pageIndex == rhs.pageIndex
    }
}
