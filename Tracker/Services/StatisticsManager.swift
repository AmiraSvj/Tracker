import Foundation

struct StatisticsData {
    let bestPeriod: Int
    let idealDays: Int
    let completedTrackers: Int // Общее количество выполненных трекеров (записей)
    let averageValue: Double
}

protocol StatisticsManagerProtocol {
    func calculateStatistics() -> StatisticsData
}

final class StatisticsManager: StatisticsManagerProtocol {
    
    private let trackerStore = TrackerStore()
    private let recordStore = TrackerRecordStore()
    private let categoryStore = TrackerCategoryStore()
    
    func calculateStatistics() -> StatisticsData {
        let bestPeriod = getBestPeriod()
        let idealDays = getIdealDays()
        let completedTrackers = getCompletedTrackers()
        let averageValue = getAverageValue()
        
        return StatisticsData(
            bestPeriod: bestPeriod,
            idealDays: idealDays,
            completedTrackers: completedTrackers,
            averageValue: averageValue
        )
    }
    
    private func getBestPeriod() -> Int {
        let records = recordStore.fetchRecords()
        
        // Группируем записи по датам
        let recordsByDate = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        
        var maxConsecutiveDays = 0
        var currentConsecutiveDays = 0
        var previousDate: Date?
        
        let sortedDates = recordsByDate.keys.sorted()
        
        for date in sortedDates {
            if let prevDate = previousDate {
                let daysDifference = Calendar.current.dateComponents([.day], from: prevDate, to: date).day ?? 0
                
                if daysDifference == 1 {
                    currentConsecutiveDays += 1
                } else {
                    maxConsecutiveDays = max(maxConsecutiveDays, currentConsecutiveDays)
                    currentConsecutiveDays = 1
                }
            } else {
                currentConsecutiveDays = 1
            }
            
            previousDate = date
        }
        
        maxConsecutiveDays = max(maxConsecutiveDays, currentConsecutiveDays)
        return maxConsecutiveDays
    }
    
    private func getIdealDays() -> Int {
        let categories = categoryStore.fetchCategories()
        let records = recordStore.fetchRecords()
        
        // Получаем все трекеры из категорий
        var allTrackers: [Tracker] = []
        for category in categories {
            allTrackers.append(contentsOf: category.trackers)
        }
        
        guard !allTrackers.isEmpty else { return 0 }
        
        let recordsByDate = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        
        var idealDaysCount = 0
        
        for (date, dayRecords) in recordsByDate {
            let completedTrackerIds = Set(dayRecords.map { $0.trackerId })
            let activeTrackersForDay = allTrackers.filter { tracker in
                tracker.isScheduled(for: date)
            }
            
            let activeTrackerIds = Set(activeTrackersForDay.map { $0.identifier })
            
            // Идеальный день - когда выполнены все активные трекеры
            if activeTrackerIds.isSubset(of: completedTrackerIds) && !activeTrackerIds.isEmpty {
                idealDaysCount += 1
            }
        }
        
        return idealDaysCount
    }
    
    private func getCompletedTrackers() -> Int {
        // Возвращаем общее количество выполненных трекеров (записей),
        // а не количество уникальных трекеров
        let records = recordStore.fetchRecords()
        return records.count
    }
    
    private func getAverageValue() -> Double {
        let categories = categoryStore.fetchCategories()
        let records = recordStore.fetchRecords()
        
        // Получаем все трекеры из категорий
        var allTrackers: [Tracker] = []
        for category in categories {
            allTrackers.append(contentsOf: category.trackers)
        }
        
        guard !allTrackers.isEmpty else { return 0 }
        
        let recordsByDate = Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.date)
        }
        
        var totalCompletedTrackers = 0
        var daysWithActivity = 0
        
        for (date, dayRecords) in recordsByDate {
            let activeTrackersForDay = allTrackers.filter { tracker in
                tracker.isScheduled(for: date)
            }
            
            if !activeTrackersForDay.isEmpty {
                totalCompletedTrackers += dayRecords.count
                daysWithActivity += 1
            }
        }
        
        return daysWithActivity > 0 ? Double(totalCompletedTrackers) / Double(daysWithActivity) : 0
    }
}
