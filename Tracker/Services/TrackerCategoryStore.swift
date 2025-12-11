import Foundation
import UIKit
import CoreData

protocol TrackerCategoryStoreProtocol {
    func createCategory(title: String) -> TrackerCategory
    func fetchCategories() -> [TrackerCategory]
    func updateCategoryTitle(_ category: TrackerCategory, newTitle: String)
    func deleteCategory(_ category: TrackerCategory)
    func getCategory(by title: String) -> TrackerCategory?
    func startObservingChanges(onUpdate: @escaping ([TrackerCategory]) -> Void)
    func stopObservingChanges()
}

final class TrackerCategoryStore: NSObject, TrackerCategoryStoreProtocol {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>?
    private var onUpdateCallback: (([TrackerCategory]) -> Void)?
    
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
    
    private func notifyUpdate() {
        guard let fetchedObjects = fetchedResultsController?.fetchedObjects else { return }
        let categories = fetchedObjects.compactMap { categoryCoreData -> TrackerCategory? in
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
        onUpdateCallback?(categories)
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
            
            // Проверяем, не существует ли уже трекер с таким ID
            let trackerFetchRequest = TrackerCoreData.fetchRequest()
            trackerFetchRequest.predicate = NSPredicate(format: "id == %@", tracker.identifier.uuidString)
            
            if let existingTrackers = try? self.context.fetch(trackerFetchRequest),
               let existingTracker = existingTrackers.first {
                // Трекер уже существует, просто добавляем его в категорию если еще не добавлен
                if let trackersSet = categoryCoreData.trackers as? Set<TrackerCoreData>,
                   !trackersSet.contains(existingTracker) {
                    categoryCoreData.addToTrackers(existingTracker)
                }
            } else {
                // Создаем новый трекер
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
                print("Failed to save tracker: \(error)")
            }
        }
    }
    
    func removeTracker(_ trackerId: UUID, fromCategoryTitle categoryTitle: String) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCategoryCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@", categoryTitle)
            
            guard let categories = try? self.context.fetch(fetchRequest),
                  let categoryCoreData = categories.first,
                  let trackersSet = categoryCoreData.trackers as? Set<TrackerCoreData> else {
                return
            }
            
            // Находим трекер для удаления
            if let trackerToRemove = trackersSet.first(where: { $0.id == trackerId.uuidString }) {
                categoryCoreData.removeFromTrackers(trackerToRemove)
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to remove tracker: \(error)")
                }
            }
        }
    }
    
    // MARK: - TrackerCategoryStoreProtocol Methods
    
    func createCategory(title: String) -> TrackerCategory {
        let categoryCoreData = TrackerCategoryCoreData(context: context)
        categoryCoreData.title = title
        
        do {
            try context.save()
        } catch {
            print("Failed to create category: \(error)")
        }
        
        return TrackerCategory(title: title, trackers: [])
    }
    
    func updateCategoryTitle(_ category: TrackerCategory, newTitle: String) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCategoryCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@", category.title)
            
            do {
                let categories = try self.context.fetch(fetchRequest)
                if let categoryCoreData = categories.first {
                    categoryCoreData.title = newTitle
                    try self.context.save()
                }
            } catch {
                print("Failed to update category: \(error)")
            }
        }
    }
    
    func deleteCategory(_ category: TrackerCategory) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerCategoryCoreData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title == %@", category.title)
            
            do {
                let categories = try self.context.fetch(fetchRequest)
                if let categoryCoreData = categories.first {
                    self.context.delete(categoryCoreData)
                    try self.context.save()
                }
            } catch {
                print("Failed to delete category: \(error)")
            }
        }
    }
    
    func getCategory(by title: String) -> TrackerCategory? {
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let categories = try context.fetch(fetchRequest)
            guard let categoryCoreData = categories.first,
                  let categoryTitle = categoryCoreData.title,
                  let trackersSet = categoryCoreData.trackers as? Set<TrackerCoreData> else {
                return nil
            }
            
            let trackers = trackersSet.compactMap { trackerCoreData -> Tracker? in
                guard let trackerIdString = trackerCoreData.id,
                      let trackerId = UUID(uuidString: trackerIdString),
                      let trackerTitle = trackerCoreData.title,
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
                    title: trackerTitle,
                    color: color,
                    schedule: schedule,
                    emoji: emoji,
                    isPinned: trackerCoreData.isPinned
                )
            }
            
            return TrackerCategory(title: categoryTitle, trackers: trackers)
        } catch {
            print("Failed to get category: \(error)")
            return nil
        }
    }
    
    func startObservingChanges(onUpdate: @escaping ([TrackerCategory]) -> Void) {
        self.onUpdateCallback = onUpdate
        
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: "TrackerCategoryStore"
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
            notifyUpdate()
        } catch {
            print("Failed to perform fetch: \(error)")
        }
    }
    
    func stopObservingChanges() {
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil
        onUpdateCallback = nil
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.storeDidUpdate()
        notifyUpdate()
    }
}

// MARK: - TrackerCategoryStoreDelegate

protocol TrackerCategoryStoreDelegate: AnyObject {
    func storeDidUpdate()
}
