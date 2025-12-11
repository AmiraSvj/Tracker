import Foundation
import YandexMobileMetrica

enum AnalyticsEvent: String {
    case open = "open"
    case close = "close"
    case click = "click"
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track = "track"
    case filter = "filter"
    case edit = "edit"
    case delete = "delete"
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func report(event: AnalyticsEvent, screen: AnalyticsScreen, item: AnalyticsItem? = nil) {
        var parameters: [String: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue
        ]
        
        if let item = item {
            parameters["item"] = item.rawValue
        }
        
        YMMYandexMetrica.reportEvent("event", parameters: parameters)
        
        // Дублируем в логи для тестирования
        print("📊 Analytics: event=\(event.rawValue), screen=\(screen.rawValue), item=\(item?.rawValue ?? "nil")")
    }
}
