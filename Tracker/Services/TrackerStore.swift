import Foundation
import UIKit
import CoreData

final class TrackerStore: NSObject {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        super.init()
    }
    
    // MARK: - Public Methods
    
    func fetchTrackers() -> [Tracker] {
        let fetchRequest = TrackerCoreData.fetchRequest()
        
        guard let trackersCoreData = try? context.fetch(fetchRequest) else {
            return []
        }
        
        return trackersCoreData.compactMap { trackerCoreData -> Tracker? in
            guard let trackerIdString = trackerCoreData.id,
                  let trackerId = UUID(uuidString: trackerIdString),
                  let title = trackerCoreData.title,
                  let emoji = trackerCoreData.emoji else {
                return nil
            }
            
            let color = UIColor(
                red: CGFloat(trackerCoreData.colorRed),
                green: CGFloat(trackerCoreData.colorGreen),
                blue: CGFloat(trackerCoreData.colorBlue),
                alpha: CGFloat(trackerCoreData.colorAlpha)
            )
            
            let schedule: [Weekday]
            if let scheduleArray = trackerCoreData.schedule as? [Int] {
                schedule = scheduleArray.compactMap { Weekday(rawValue: $0) }
            } else {
                schedule = []
            }
            
            return Tracker(
                identifier: trackerId,
                title: title,
                color: color,
                schedule: schedule,
                emoji: emoji,
                isPinned: trackerCoreData.isPinned
            )
        }
    }
    
    func addTracker(_ tracker: Tracker) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let trackerCoreData = TrackerCoreData(context: self.context)
            trackerCoreData.id = tracker.identifier.uuidString
            trackerCoreData.title = tracker.title
            trackerCoreData.emoji = tracker.emoji
            trackerCoreData.isPinned = tracker.isPinned
            
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            tracker.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            trackerCoreData.colorRed = Double(red)
            trackerCoreData.colorGreen = Double(green)
            trackerCoreData.colorBlue = Double(blue)
            trackerCoreData.colorAlpha = Double(alpha)
            
            trackerCoreData.schedule = tracker.schedule.map { $0.rawValue }
            
            do {
                try self.context.save()
            } catch {
                print("Failed to save tracker: \(error)")
            }
        }
    }
    
    func deleteTracker(withId id: UUID) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)
            
            if let trackers = try? self.context.fetch(fetchRequest) {
                trackers.forEach { self.context.delete($0) }
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to delete tracker: \(error)")
                }
            }
        }
    }
    
    func updateTracker(_ tracker: Tracker) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.identifier.uuidString)
            
            if let trackers = try? self.context.fetch(fetchRequest),
               let trackerCoreData = trackers.first {
                trackerCoreData.title = tracker.title
                trackerCoreData.emoji = tracker.emoji
                trackerCoreData.isPinned = tracker.isPinned
                
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                tracker.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                trackerCoreData.colorRed = Double(red)
                trackerCoreData.colorGreen = Double(green)
                trackerCoreData.colorBlue = Double(blue)
                trackerCoreData.colorAlpha = Double(alpha)
                
                trackerCoreData.schedule = tracker.schedule.map { $0.rawValue }
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to update tracker: \(error)")
                }
            }
        }
    }
    
    func getTracker(by id: UUID) -> Tracker? {
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)
        
        guard let trackers = try? context.fetch(fetchRequest),
              let trackerCoreData = trackers.first,
              let trackerIdString = trackerCoreData.id,
              let trackerId = UUID(uuidString: trackerIdString),
              let title = trackerCoreData.title,
              let emoji = trackerCoreData.emoji else {
            return nil
        }
        
        let color = UIColor(
            red: CGFloat(trackerCoreData.colorRed),
            green: CGFloat(trackerCoreData.colorGreen),
            blue: CGFloat(trackerCoreData.colorBlue),
            alpha: CGFloat(trackerCoreData.colorAlpha)
        )
        
        let schedule: [Weekday]
        if let scheduleArray = trackerCoreData.schedule as? [Int] {
            schedule = scheduleArray.compactMap { Weekday(rawValue: $0) }
        } else {
            schedule = []
        }
        
        return Tracker(
            identifier: trackerId,
            title: title,
            color: color,
            schedule: schedule,
            emoji: emoji,
            isPinned: trackerCoreData.isPinned
        )
    }
    
    func togglePinTracker(_ tracker: Tracker, completion: @escaping () -> Void = {}) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tracker.identifier.uuidString)
            
            if let trackers = try? self.context.fetch(fetchRequest),
               let trackerCoreData = trackers.first {
                trackerCoreData.isPinned = !trackerCoreData.isPinned
                
                do {
                    try self.context.save()
                    DispatchQueue.main.async {
                        completion()
                    }
                } catch {
                    print("Failed to toggle pin tracker: \(error)")
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}
