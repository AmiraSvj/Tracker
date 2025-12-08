import UIKit

struct TrackerCategoryData: Codable {
    let title: String
    let trackers: [TrackerData]
}

struct TrackerData: Codable {
    let identifier: String
    let title: String
    let colorRed: CGFloat
    let colorGreen: CGFloat
    let colorBlue: CGFloat
    let colorAlpha: CGFloat
    let schedule: [Int]
    let emoji: String
    let isPinned: Bool
}

struct TrackerRecordData: Codable {
    let trackerId: String
    let date: TimeInterval
}

class DataStorageService {
    static let shared = DataStorageService()
    
    private let categoriesKey = "SavedCategories"
    private let completedTrackersKey = "CompletedTrackers"
    
    private init() {}
    
    // MARK: - Save Categories
    
    func saveCategories(_ categories: [TrackerCategory]) {
        let categoriesData = categories.map { category in
            TrackerCategoryData(
                title: category.title,
                trackers: category.trackers.map { tracker in
                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var alpha: CGFloat = 0
                    tracker.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    
                    return TrackerData(
                        identifier: tracker.identifier.uuidString,
                        title: tracker.title,
                        colorRed: red,
                        colorGreen: green,
                        colorBlue: blue,
                        colorAlpha: alpha,
                        schedule: tracker.schedule.map { $0.rawValue },
                        emoji: tracker.emoji,
                        isPinned: tracker.isPinned
                    )
                }
            )
        }
        
        if let encoded = try? JSONEncoder().encode(categoriesData) {
            UserDefaults.standard.set(encoded, forKey: categoriesKey)
            print("💾 Saved \(categories.count) categories")
        }
    }
    
    // MARK: - Load Categories
    
    func loadCategories() -> [TrackerCategory] {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey),
              let categoriesData = try? JSONDecoder().decode([TrackerCategoryData].self, from: data) else {
            return []
        }
        
        let categories = categoriesData.map { categoryData in
            let trackers = categoryData.trackers.map { trackerData in
                let color = UIColor(
                    red: trackerData.colorRed,
                    green: trackerData.colorGreen,
                    blue: trackerData.colorBlue,
                    alpha: trackerData.colorAlpha
                )
                
                let schedule = trackerData.schedule.compactMap { Weekday(rawValue: $0) }
                
                var tracker = Tracker(
                    identifier: UUID(uuidString: trackerData.identifier) ?? UUID(),
                    title: trackerData.title,
                    color: color,
                    schedule: schedule,
                    emoji: trackerData.emoji
                )
                // isPinned имеет значение по умолчанию false, поэтому не передаем его явно
                return tracker
            }
            
            return TrackerCategory(title: categoryData.title, trackers: trackers)
        }
        
        print("📂 Loaded \(categories.count) categories")
        return categories
    }
    
    // MARK: - Save Completed Trackers
    
    func saveCompletedTrackers(_ completedTrackers: Set<TrackerRecord>) {
        let recordsData = completedTrackers.map { record in
            TrackerRecordData(
                trackerId: record.trackerId.uuidString,
                date: record.date.timeIntervalSince1970
            )
        }
        
        if let encoded = try? JSONEncoder().encode(recordsData) {
            UserDefaults.standard.set(encoded, forKey: completedTrackersKey)
            print("💾 Saved \(completedTrackers.count) completed trackers")
        }
    }
    
    // MARK: - Load Completed Trackers
    
    func loadCompletedTrackers() -> Set<TrackerRecord> {
        guard let data = UserDefaults.standard.data(forKey: completedTrackersKey),
              let recordsData = try? JSONDecoder().decode([TrackerRecordData].self, from: data) else {
            return []
        }
        
        let records = recordsData.compactMap { recordData -> TrackerRecord? in
            guard let trackerId = UUID(uuidString: recordData.trackerId) else { return nil }
            let date = Date(timeIntervalSince1970: recordData.date)
            return TrackerRecord(trackerId: trackerId, date: date)
        }
        
        print("📂 Loaded \(records.count) completed trackers")
        return Set(records)
    }
}

