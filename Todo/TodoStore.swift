//
//  TodoStore.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 11/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import Foundation
import CoreData

private let ModelVersion = "2"
private enum ModelKey: String {
    case Version        = "model_version"
}

enum ModelError: ErrorType {
    case Unknown
    case UnsuccessfulRead(String)
    case UnsuccessfulWrite
    case UnsuccessfulInitialization
}

typealias MCompletion               = (error: ModelError?) -> ()
typealias MCompletionWithResult     = (result: Any?, error: ModelError?) -> ()

private let EntityNameTodoItem = "TodoItem"

let TodoItemDeletedNotification = "todo_item_deleted"
let TodoItemCreatedNotification = "todo_item_created"
let TodoItemToggleCompletedNotification = "todo_item_toggle_completed"

class TodoStore {

    private var registered = false
    
    static let sharedInstance = TodoStore()

    func registerWithDispatcher() {
        
        if registered {
            return
        }
        
        Dispatcher.sharedInstance.register { (payload) -> Void in
            
            if payload[TodoAction] == nil {
                return
            }
            
            let action = payload[TodoAction] as? String
            
            if action == TodoActionCreate {
                if let title = payload[TodoItemTitle] as? String {
                    self.createTodoItem(title, completion: { (saved, _) -> Void in
                        if saved != nil && saved! as! Bool {
                            self.notifyTodoItemCreated()
                        }
                    })
                }
    
            } else if action == TodoActionDelete {
                if let itemId = payload[TodoItemId] as? String {
                    self.deleteTodoItem(itemId, completion: { (saved, _) -> Void in
                        if saved != nil && saved! as! Bool {
                            self.notifyTodoItemDeleted()
                        }
                    })
                }
            
            } else if action == TodoActionToggleCompleted {
                if let itemId = payload[TodoItemId] as? String {
                    self.toggleCompleted(itemId, completion: { (saved, _) -> Void in
                        if saved != nil && saved! as! Bool {
                            self.notifyTodoItemToggleCompleted()
                        }
                    })
                }
            }
        }
        
        registered = true
    }
    
    func notifyTodoItemCreated() {
        NSNotificationCenter.defaultCenter().postNotificationName(TodoItemCreatedNotification, object: nil)
    }
    
    func notifyTodoItemDeleted() {
        NSNotificationCenter.defaultCenter().postNotificationName(TodoItemDeletedNotification, object: nil)
    }
    
    func notifyTodoItemToggleCompleted() {
        NSNotificationCenter.defaultCenter().postNotificationName(TodoItemToggleCompletedNotification, object: nil)
    }
    
    func allTodoItems(completion: MCompletionWithResult?) {
        readAsynchronously { moc in
            
            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            do {
                guard let todoItems = try moc.executeFetchRequest(request) as? [TodoItem] else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(result: [], error: nil)
                    })
                    return
                }

                guard !todoItems.isEmpty else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(result: [], error: nil)
                    })
                    return
                }

                let vos = todoItems.map {  TodoItemVO(todoItem: $0) }.filter { $0 != nil }.map { $0! }
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(result: vos, error: nil)
                })

            } catch {
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(result: nil, error: .UnsuccessfulRead("Unable to retrieve todo items"))
                })
            }
        }
    }
    
    func createTodoItem(title: String, completion: MCompletionWithResult?) {

        writeAsychronously({ moc in

            let todoItem = NSEntityDescription.insertNewObjectForEntityForName(EntityNameTodoItem, inManagedObjectContext: moc) as! TodoItem

            todoItem.itemId = NSUUID().UUIDString
            todoItem.title = title
            todoItem.createdAt = NSDate()
            todoItem.completed = NSNumber(bool: false)

            }) { error in

                guard error == nil else {
                    completion?(result: false, error: error)
                    return
                }

                completion?(result: true, error: nil)

        }

    }
    
    func deleteTodoItem(itemId: String, completion: MCompletionWithResult?) {


        writeAsychronously({ moc in

            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.predicate = NSPredicate(format: "itemId == %@", itemId)

            do {

                if let todoItem = (try moc.executeFetchRequest(request)).first as? NSManagedObject {
                    moc.deleteObject(todoItem)
                }

            } catch {
                completion?(result: false, error: .UnsuccessfulRead("Item does not exist"))
                return
            }

            }) { error in

                guard error == nil else {
                    completion?(result: false, error: error)
                    return
                }

                completion?(result: true, error: nil)
                
        }

    }
    
    func toggleCompleted(itemId: String, completion: MCompletionWithResult?) {


        writeAsychronously({ moc in

            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.predicate = NSPredicate(format: "itemId == %@", itemId)

            do {

                if let todoItem = (try moc.executeFetchRequest(request)).first as? TodoItem {
                    todoItem.completed = NSNumber(bool: !(todoItem.completed!.boolValue))
                }

            } catch {
                completion?(result: false, error: .UnsuccessfulRead("Item does not exist"))
                return
            }

            }) { error in

                guard error == nil else {
                    completion?(result: false, error: error)
                    return
                }

                completion?(result: true, error: nil)

        }

    }

    // MARK: - Core data set up

    lazy var applicationStoresDirectory: NSURL? = {

        let fm = NSFileManager.defaultManager()

        guard let url = fm.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last?
            .URLByAppendingPathComponent("Stores") else {
                return nil
        }

        guard let path = url.path else {
            return nil
        }

        if !fm.fileExistsAtPath(path) {
            do {
                try fm.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)

            } catch _ {
                NSLog("Unable to create directory for data stores")
                return nil
            }
        }

        return url

    }()

    lazy var managedObjectModel: NSManagedObjectModel? = {

        let url = NSBundle.mainBundle().URLForResource("Todo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL:url)

    }()


    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {

        let storeURL
        = self.applicationStoresDirectory?.URLByAppendingPathComponent("Todo.sqlite")

        func isModelVersionCurrent() -> Bool {

            NSLog("Checking model version...")

            let version = NSUserDefaults.standardUserDefaults().stringForKey(ModelKey.Version.rawValue)
            return version != nil && version! == ModelVersion

        }

        func deleteOldStore(storeURL: NSURL?) -> Bool {

            guard let path = storeURL?.path else {
                return false
            }

            let fm = NSFileManager.defaultManager()
            guard fm.fileExistsAtPath(path) else {
                NSLog("No store exists at path!")
                return true
            }

            do {
                try fm.removeItemAtURL(storeURL!)
                NSLog("Successfully removed incompatible store")
                return true

            } catch {
                NSLog("Failed to remove incompatible store")
                return false
            }

        }

        func persistenceStoreCoordinatorForStore(storeURL: NSURL?) -> NSPersistentStoreCoordinator? {

            guard let managedObjectModel = self.managedObjectModel else {
                return nil
            }

            let coordinator:NSPersistentStoreCoordinator
            = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

            do {
                try coordinator.addPersistentStoreWithType(
                    NSSQLiteStoreType,
                    configuration: nil,
                    URL: storeURL,
                    options: nil)

            } catch {
                NSLog("Unable to add persistent store")
                return nil
            }

            return coordinator

        }

        func updateModelVersion() {

            NSLog("Updating model version")

            let userDefaults = NSUserDefaults.standardUserDefaults()

            userDefaults.setObject(ModelVersion, forKey: ModelKey.Version.rawValue)
            userDefaults.synchronize()

        }

        if isModelVersionCurrent() {
            return persistenceStoreCoordinatorForStore(storeURL)

        } else {
            if deleteOldStore(storeURL) {

                if let coordinator = persistenceStoreCoordinatorForStore(storeURL) {
                    updateModelVersion()
                    return coordinator

                } else {
                    return nil
                }

            } else {
                return nil
            }
        }

    }()

    lazy var managedObjectContext:NSManagedObjectContext? = {

        guard let
            coordinator = self.persistentStoreCoordinator else {
                return nil
        }

        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator
        return moc

    }()

    lazy var privateManagedObjectContext:NSManagedObjectContext? = {

        guard let
            coordinator = self.persistentStoreCoordinator,
            moc = self.managedObjectContext else {
                return nil
        }

        let privateMoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateMoc.persistentStoreCoordinator = coordinator
        
        NSNotificationCenter.defaultCenter()
            .addObserverForName(NSManagedObjectContextDidSaveNotification, object: moc, queue: nil) { notification in
                privateMoc.performBlock {
                    privateMoc.mergeChangesFromContextDidSaveNotification(notification)
                }
        }
        
        return privateMoc
        
    }()
    
}

// MARK: - Async Read / Write

extension TodoStore {

    func writeAsychronously(operation:(NSManagedObjectContext) -> (), completion: MCompletion?) {
        if let moc = self.privateManagedObjectContext {
            moc.performBlock({
                operation(moc)

                do {

                    if moc.hasChanges {
                        try moc.save()
                    }

                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(error: nil)
                    }

                } catch {
                    NSLog("Failed to save changes")

                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(error: .UnsuccessfulWrite)
                    }

                }
            })
        }
    }

    func readAsynchronously(operation:(NSManagedObjectContext)->Void) {
        if let moc = self.privateManagedObjectContext {
            moc.performBlock({
                operation(moc)
            })
        }
    }
}

