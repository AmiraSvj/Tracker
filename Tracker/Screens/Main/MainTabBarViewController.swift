import UIKit

final class MainTabBarViewController: UITabBarController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarAppearance()
        configureViewControllers()
    }
    
    // MARK: - Private Methods
    
    private func configureTabBarAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .gray
        tabBar.backgroundColor = UIColor.systemBackground
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = false
        
        tabBar.layer.borderWidth = 1.0 / UIScreen.main.scale
        tabBar.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).cgColor
        tabBar.clipsToBounds = true
    }
    
    private func configureViewControllers() {
        let trackersVC = TrackersViewController()
        let statisticsVC = StatisticsViewController()
        
        let trackersImage = UIImage(resource: .trackersItem).withRenderingMode(.alwaysTemplate)
        let statisticsImage = UIImage(resource: .rabbitItem).withRenderingMode(.alwaysTemplate)
        
        trackersVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Trackers", comment: "Trackers tab"),
            image: trackersImage,
            selectedImage: nil
        )
        
        statisticsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Statistics", comment: "Statistics tab"),
            image: statisticsImage,
            selectedImage: nil
        )
        
        let trackersNC = UINavigationController(rootViewController: trackersVC)
        let statisticsNC = UINavigationController(rootViewController: statisticsVC)
        
        viewControllers = [trackersNC, statisticsNC]
    }
}

