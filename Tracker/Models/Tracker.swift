import UIKit

struct Tracker {
    let identifier: UUID
    let title: String
    let color: UIColor
    let schedule: [Weekday]
    let emoji: String
    let isPinned: Bool
}

enum Weekday: Int, CaseIterable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var numericValue: Int {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
    
    var abbreviatedName: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
}

extension Tracker {
    func isScheduled(for date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Calendar.weekday: Sunday=1, Monday=2, ..., Saturday=7
        // Weekday enum: Monday=1, Tuesday=2, ..., Sunday=7
        let filterWeekday: Int
        if weekday == 1 {
            filterWeekday = 7 // Sunday
        } else {
            filterWeekday = weekday - 1 // Monday=1, Tuesday=2, etc.
        }
        
        return schedule.contains { $0.numericValue == filterWeekday }
    }
}

