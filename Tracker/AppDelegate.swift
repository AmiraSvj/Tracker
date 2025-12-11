import UIKit
import YandexMobileMetrica

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Инициализация AppMetrica
        // Замените "your-api-key-here" на ваш реальный API ключ из AppMetrica
        if let configuration = YMMYandexMetricaConfiguration(apiKey: "your-api-key-here") {
            YMMYandexMetrica.activate(with: configuration)
        }
        
        window = UIWindow()
        
        // Проверяем, был ли пройден онбординг
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "OnboardingCompleted")
        
        if hasCompletedOnboarding {
            // Если онбординг пройден, показываем основной экран
            window?.rootViewController = MainTabBarViewController()
        } else {
            // Если онбординг не пройден, показываем онбординг
            window?.rootViewController = OnboardingViewController()
        }
        
        window?.makeKeyAndVisible()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
}

