//
//  OnboardingViewController.swift
//  Tracker
//
//  Created by Zhukov Konstantin on 05.11.2025.
//

import UIKit

final class OnboardingViewController: UIViewController {

    // MARK: - UI Elements
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let pageControl = UIPageControl()
    private let actionButton = UIButton(type: .system)

    // MARK: - Data
    private var pages: [OnboardingPageViewController] = []
    private var currentPageIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPages()
        setupPageViewController()
        setupPageControl()
        setupActionButton()
        
        // Убеждаемся, что кнопка и PageControl отображаются поверх всех страниц
        view.bringSubviewToFront(actionButton)
        view.bringSubviewToFront(pageControl)
    }

    private func setupPages() {
        let page1 = OnboardingPageViewController(
            pageIndex: 0,
            titleText: "Отслеживайте только\nто, что хотите",
            backgroundImageName: "Onboarding1"
        )

        let page2 = OnboardingPageViewController(
            pageIndex: 1,
            titleText: "Даже если это\nне литры воды и йога",
            backgroundImageName: "Onboarding2"
        )

        pages = [page1, page2]
    }

    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        pageViewController.dataSource = self
        pageViewController.delegate = self

        // Устанавливаем первую страницу
        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: false)
        }
    }

    private func setupPageControl() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor(named: "Gray")?.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor(named: "BlackDay")
        pageControl.addTarget(self, action: #selector(pageControlValueChanged), for: .valueChanged)
        
        // Настройка размеров точек
        if #available(iOS 14.0, *) {
            pageControl.preferredIndicatorImage = nil
        }
        
        // Настройка стиля точек
        pageControl.hidesForSinglePage = false

        view.addSubview(pageControl)

        // Адаптивные constraints для разных размеров экранов
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        // Базовые значения из дизайна Figma (375x812 - iPhone X/XS/11 Pro)
        let baseHeight: CGFloat = 812
        let baseWidth: CGFloat = 375
        let baseTopOffset: CGFloat = 638
        let baseLeadingOffset: CGFloat = 178
        
        // Масштабируем позицию PageControl пропорционально размерам экрана
        let topOffset = (screenHeight / baseHeight) * baseTopOffset
        let leadingOffset = (screenWidth / baseWidth) * baseLeadingOffset

        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset)
        ])
    }
    
    private func setupActionButton() {
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitle("Вот это технологии!", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        
        // Настройка шрифта текста кнопки: SF Pro Medium, 16px, line-height 22px
        let buttonFont = UIFont(name: "SFPro-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        actionButton.titleLabel?.font = buttonFont
        actionButton.titleLabel?.textAlignment = .center
        
        // Настройка line-height для текста кнопки
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 22.0 / 16.0
        paragraphStyle.alignment = .center
        
        let attributedTitle = NSAttributedString(
            string: "Вот это технологии!",
            attributes: [
                .font: buttonFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .kern: 0.0
            ]
        )
        actionButton.setAttributedTitle(attributedTitle, for: .normal)
        
        actionButton.backgroundColor = UIColor(named: "BlackDay")
        actionButton.layer.cornerRadius = 16
        actionButton.layer.masksToBounds = true
        
        // Вертикальное выравнивание текста по центру
        actionButton.contentVerticalAlignment = .center

        // Padding: top 19px, right 32px, bottom 19px, left 32px
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 19, left: 32, bottom: 19, right: 32)
        
        // Настройка titleEdgeInsets для вертикального позиционирования текста
        // Небольшое смещение вверх для лучшего визуального центрирования
        actionButton.titleEdgeInsets = UIEdgeInsets(top: -5, left: 0, bottom: 5, right: 0)
        
        // Дополнительная настройка для точного центрирования текста
        actionButton.titleLabel?.numberOfLines = 1
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = false

        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)

        view.addSubview(actionButton)

        // Адаптивные constraints для разных размеров экранов
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        // Базовые значения из дизайна Figma (375x812 - iPhone X/XS/11 Pro)
        let baseHeight: CGFloat = 812
        let baseWidth: CGFloat = 375
        let baseTopOffset: CGFloat = 668
        let baseButtonWidth: CGFloat = 335
        let baseLeadingOffset: CGFloat = 20
        
        // Масштабируем позицию кнопки пропорционально размерам экрана
        let topOffset = (screenHeight / baseHeight) * baseTopOffset
        let leadingOffset = (screenWidth / baseWidth) * baseLeadingOffset
        
        // Адаптивная ширина: сохраняем пропорции относительно базовой ширины
        // Ограничиваем максимальной шириной с учетом отступов
        let buttonWidth = min(baseButtonWidth * (screenWidth / baseWidth), screenWidth - (leadingOffset * 2))

        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingOffset),
            actionButton.topAnchor.constraint(equalTo: view.topAnchor, constant: topOffset),
            actionButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            actionButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func actionButtonTapped() {
        finishOnboarding()
    }

    @objc private func pageControlValueChanged() {
        let direction: UIPageViewController.NavigationDirection = pageControl.currentPage > currentPageIndex ? .forward : .reverse

        if let targetPage = pages[safe: pageControl.currentPage] {
            pageViewController.setViewControllers([targetPage], direction: direction, animated: true)
            currentPageIndex = pageControl.currentPage
        }
    }

    private func finishOnboarding() {
        // Сохраняем флаг о том, что онбординг пройден
        UserDefaults.standard.set(true, forKey: "OnboardingCompleted")

        // Переходим к основному экрану
        let tabBarController = MainTabBarViewController()
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.modalTransitionStyle = .crossDissolve

        // Заменяем root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? OnboardingPageViewController,
              let currentIndex = pages.firstIndex(of: currentVC),
              currentIndex > 0 else {
            return nil
        }

        return pages[currentIndex - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? OnboardingPageViewController,
              let currentIndex = pages.firstIndex(of: currentVC),
              currentIndex < pages.count - 1 else {
            return nil
        }

        return pages[currentIndex + 1]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? OnboardingPageViewController,
              let currentIndex = pages.firstIndex(of: currentVC) else {
            return
        }

        currentPageIndex = currentIndex
        pageControl.currentPage = currentIndex
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
