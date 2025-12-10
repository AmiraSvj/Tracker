import Foundation
import CoreData

final class TrackerRecordStore: NSObject {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.context) {
        self.context = context
        super.init()
    }
    
    // MARK: - Public Methods
    
    func fetchRecords() -> Set<TrackerRecord> {
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        
        guard let recordsCoreData = try? context.fetch(fetchRequest) else {
            return []
        }
        
        let calendar = Calendar.current
        var records = Set<TrackerRecord>()
        
        for recordCoreData in recordsCoreData {
            guard let trackerIdString = recordCoreData.trackerId,
                  let trackerId = UUID(uuidString: trackerIdString) else {
                continue
            }
            
            let date = recordCoreData.date ?? Date()
            let normalizedDate = calendar.startOfDay(for: date)
            
            records.insert(TrackerRecord(trackerId: trackerId, date: normalizedDate))
        }
        
        return records
    }
    
    func addRecord(_ record: TrackerRecord) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Проверяем, не существует ли уже такая запись
            let fetchRequest = TrackerRecordCoreData.fetchRequest()
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: record.date)
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate) else {
                return
            }
            
            fetchRequest.predicate = NSPredicate(
                format: "trackerId == %@ AND date >= %@ AND date < %@",
                record.trackerId.uuidString,
                normalizedDate as NSDate,
                nextDay as NSDate
            )
            
            if let existingRecords = try? self.context.fetch(fetchRequest),
               existingRecords.isEmpty {
                let recordCoreData = TrackerRecordCoreData(context: self.context)
                recordCoreData.trackerId = record.trackerId.uuidString
                recordCoreData.date = normalizedDate
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to save record: \(error)")
                }
            }
        }
    }
    
    func deleteRecord(_ record: TrackerRecord) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = TrackerRecordCoreData.fetchRequest()
            let calendar = Calendar.current
            let normalizedDate = calendar.startOfDay(for: record.date)
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate) else {
                return
            }
            
            fetchRequest.predicate = NSPredicate(
                format: "trackerId == %@ AND date >= %@ AND date < %@",
                record.trackerId.uuidString,
                normalizedDate as NSDate,
                nextDay as NSDate
            )
            
            if let records = try? self.context.fetch(fetchRequest) {
                records.forEach { self.context.delete($0) }
                
                do {
                    try self.context.save()
                } catch {
                    print("Failed to delete record: \(error)")
                }
            }
        }
    }
    
    func countRecords(for trackerId: UUID) -> Int {
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "trackerId == %@", trackerId.uuidString)
        
        guard let count = try? context.count(for: fetchRequest) else {
            return 0
        }
        
        return count
    }
}
