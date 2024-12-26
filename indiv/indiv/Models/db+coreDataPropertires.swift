import CoreData

extension db {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<db> {
        return NSFetchRequest<db>(entityName: "Item")
    }

    @NSManaged public var name: String?
    @NSManaged public var desc: String?
    @NSManaged public var file: String?
    @NSManaged public var photobg: String?
}
