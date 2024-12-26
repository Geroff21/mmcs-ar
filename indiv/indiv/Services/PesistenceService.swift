import CoreData

class PersistenceService {
    
    private init() {}
    
    static var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    static var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "db")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // Сохраняем контекст
    static func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // Добавление нового элемента
    static func addItem(name: String, description: String, filePath: String?, photobg: String?) {
        let context = persistentContainer.viewContext
        let newItem = Item(context: context)
        newItem.name = name
        newItem.desc = description
        newItem.file = filePath
        newItem.photobg = photobg
        
        saveContext()
    }
    
    // Получение всех элементов
    static func fetchItems() -> [Item]? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            return items
        } catch {
            print("Ошибка при получении данных: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Получение элемента по имени
    static func fetchItemByName(name: String) -> Item? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            // Фильтрация на уровне Swift
            return items.first { $0.name?.lowercased() == name.lowercased() }
        } catch {
            print("Ошибка при получении объекта: \(error.localizedDescription)")
            return nil
        }
    }

    
    // Обновление элемента
    static func updateItem(item: Item, newName: String, newDescription: String, newFilePath: String?, newPhotobg: String?) {
        let context = persistentContainer.viewContext
        item.name = newName
        item.desc = newDescription
        item.file = newFilePath
        item.photobg = newPhotobg
        
        saveContext()
    }
    
    // Удаление элемента
    static func deleteItem(item: Item) {
        let context = persistentContainer.viewContext
        context.delete(item)
        
        saveContext()
    }
    
    // Удаление всех элементов
    static func deleteAllItems() {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        do {
            let items = try context.fetch(fetchRequest)
            for item in items {
                context.delete(item)
            }
            saveContext()
        } catch {
            print("Ошибка при удалении объектов: \(error.localizedDescription)")
        }
    }
}
