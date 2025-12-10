import Foundation
import UIKit
import CoreData

final class TrackerCategoryStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>?
    
    weak var delegate: TrackerCategoryStoreDelegate?
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func fetchCategories() -> [TrackerCategory] {
        guard let fetchedObjects = fetchedResultsController?.fetchedObjects else {
            return []
        }
        
        return fetchedObjects.compactMap { categoryCoreData -> TrackerCategory? in
            guard let title = categoryCoreData.title,
                  let trackersSet = categoryCoreData.trackers as? Set<TrackerCoreData> else {
                return nil
            }
            
            let trackers = trackersSet.compactMap { trackerCoreData -> Tracker? in
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
            
            return TrackerCategory(title: title, trackers: trackers)
        }
    }
    
    func addCategory(_ category: TrackerCategory) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let categoryCoreData = TrackerCategoryCoreData(context: self.context)
            categoryCoreData.title = category.title
            
            // Добавляем трекеры
            for tracker in category.trackers {
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
                
                categoryCoreData.addToTrackers(trackerCoreData)
            }
            
            do {
                try self.context.save()
            } catch {
                print("Failed to save category: \(error)")
            }
        }
    }
    
    func addTracker(_ tracker: Tracker, toCategoryTitle categoryTitle: String) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCategoryCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@", categoryTitle)
            
            guard let categories = try? self.context.fetch(fetchRequest),
                  let categoryCoreData = categories.first else {
                // Создаем новую категорию, если не найдена
                let newCategory = TrackerCategory(title: categoryTitle, trackers: [tracker])
                self.addCategory(newCategory)
                return
            }
            
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
            
            categoryCoreData.addToTrackers(trackerCoreData)
            
            do {
                try self.context.save()
            } catch {
                print("Failed to save tracker: \(error)")
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeDidUpdate()
    }
}

// MARK: - TrackerCategoryStoreDelegate

protocol TrackerCategoryStoreDelegate: AnyObject {
    func storeDidUpdate()
}
