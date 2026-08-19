import CoreData
import Foundation

@MainActor
final class KivroWalletMirrorStore {
    static let shared = KivroWalletMirrorStore()

    private let entityName = "KivroWalletBalance"
    private let context: NSManagedObjectContext
    private var isAvailable = false

    private init() {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let userIdentifier = NSAttributeDescription()
        userIdentifier.name = "userIdentifier"
        userIdentifier.attributeType = .stringAttributeType

        let balance = NSAttributeDescription()
        balance.name = "balance"
        balance.attributeType = .integer64AttributeType
        balance.defaultValue = Int64(0)

        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = .dateAttributeType

        entity.properties = [userIdentifier, balance, updatedAt]
        entity.uniquenessConstraints = [["userIdentifier"]]
        model.entities = [entity]

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        self.context = context

        do {
            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: try Self.makeStoreURL(),
                options: [
                    NSMigratePersistentStoresAutomaticallyOption: true,
                    NSInferMappingModelAutomaticallyOption: true
                ]
            )
            isAvailable = true
        } catch {
            isAvailable = false
        }
    }

    func setBalance(_ balance: Int, for userIdentifier: String) -> Bool {
        guard isAvailable, balance >= 0 else { return false }
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
        let record = (try? context.fetch(request).first)
            ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        record.setValue(userIdentifier, forKey: "userIdentifier")
        record.setValue(Int64(balance), forKey: "balance")
        record.setValue(Date(), forKey: "updatedAt")
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    func deleteBalance(for userIdentifier: String) -> Bool {
        guard isAvailable else { return false }
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
        do {
            try context.fetch(request).forEach(context.delete)
            if context.hasChanges { try context.save() }
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    private static func makeStoreURL() throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseDirectory.appendingPathComponent("Kivro", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("KivroWallet.sqlite")
    }
}
