//
//  TodoStore.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 11/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import Foundation
import CoreData

typealias CompletionBlockWithResult = (AnyObject?, NSError?)->Void

private let EntityNameTodoItem = "TodoItem"
private let ErrorDomain = "com.hw.todoitem.store"
private enum ErrorCode: Int {
    case ReadError = 1, WriteError
}

let TodoItemDeletedNotification = "todo_item_deleted"
let TodoItemCreatedNotification = "todo_item_created"
let TodoItemToggleCompletedNotification = "todo_item_toggle_completed"

private let _sharedInstance = TodoStore()

class TodoStore {
    private var registered = false
    
    class var sharedInstance:TodoStore {
        return _sharedInstance
    }
    
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
                    self.createTodoItem(title, completionWithResult: { (saved, _) -> Void in
                        if saved != nil && saved! as Bool {
                            self.notifyTodoItemCreated()
                        }
                    })
                }
    
            } else if action == TodoActionDelete {
                if let itemId = payload[TodoItemId] as? String {
                    self.deleteTodoItem(itemId, completionWithResult: { (saved, _) -> Void in
                        if saved != nil && saved! as Bool {
                            self.notifyTodoItemDeleted()
                        }
                    })
                }
            
            } else if action == TodoActionToggleCompleted {
                if let itemId = payload[TodoItemId] as? String {
                    self.toggleCompleted(itemId, completionWithResult: { (saved, _) -> Void in
                        if saved != nil && saved! as Bool {
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
    
    func allTodoItems(completionWithResult:CompletionBlockWithResult) {
        readAsynchronously { (moc) -> Void in
            
            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.resultType = .DictionaryResultType
            
            var error:NSError? = nil
            if let todoItems = moc.executeFetchRequest(request, error: &error) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionWithResult(todoItems, nil)
                })
            
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionWithResult(nil, self.makeReadError("Unable to retrieve todo items"))
                })
            }
        }
    }
    
    func createTodoItem(title:String, completionWithResult:CompletionBlockWithResult) {
        writeAsynchronously { (moc) -> Void in
            let todoItem = NSEntityDescription.insertNewObjectForEntityForName(EntityNameTodoItem, inManagedObjectContext: moc) as TodoItem
            
            todoItem.itemId = NSUUID().UUIDString
            todoItem.title = title
            todoItem.createdAt = NSDate()
            todoItem.completed = NSNumber(bool: false)
            
            var error:NSError?
            var saved = false
            
            if moc.hasChanges {
                saved = moc.save(&error)
                if saved {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        var mainSaveError:NSError?
                        let mainSaved = moc.parentContext?.save(&mainSaveError)
                        completionWithResult(mainSaved, mainSaveError)
                    })
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionWithResult(saved, error)
            })
        }
    }
    
    func deleteTodoItem(itemId:String, completionWithResult:CompletionBlockWithResult) {
        writeAsynchronously { (moc) -> Void in
            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.predicate = NSPredicate(format: "itemId == %@", itemId)
            
            var error:NSError?
            if let todoItems = moc.executeFetchRequest(request, error: &error) {
                if let todoItem = todoItems.first as? NSManagedObject {
                    moc.deleteObject(todoItem)
                }
            }
            
            var saved = false
            
            if moc.hasChanges {
                saved = moc.save(&error)
                if saved {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        var mainSaveError:NSError?
                        let mainSaved = moc.parentContext?.save(&mainSaveError)
                        completionWithResult(mainSaved, mainSaveError)
                    })
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionWithResult(saved, error)
            })
        }
    }
    
    func toggleCompleted(itemId:String, completionWithResult:CompletionBlockWithResult) {
        writeAsynchronously { (moc) -> Void in
            let request = NSFetchRequest(entityName: EntityNameTodoItem)
            request.predicate = NSPredicate(format: "itemId == %@", itemId)
            
            var error:NSError?
            if let todoItems = moc.executeFetchRequest(request, error: &error) {
                if let todoItem = todoItems.first as? NSManagedObject {
                    (todoItem as TodoItem).completed = NSNumber(bool: !((todoItem as TodoItem).completed!.boolValue))
                }
            }
            
            var saved = false
            
            if moc.hasChanges {
                saved = moc.save(&error)
                if saved {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        var mainSaveError:NSError?
                        let mainSaved = moc.parentContext?.save(&mainSaveError)
                        completionWithResult(mainSaved, mainSaveError)
                    })
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completionWithResult(saved, error)
            })
        }
    }
    
    
    func makeReadError(reason:String)->NSError {
        var info = [NSLocalizedDescriptionKey:"Read Error", NSLocalizedFailureReasonErrorKey: reason]
        return NSError(domain: ErrorDomain, code: ErrorCode.ReadError.rawValue, userInfo: info)
    }
    
    func writeAsynchronously(operation:(NSManagedObjectContext)->Void ) {
        if let moc = self.privateManagedObjectContext {
            moc.performBlock({
                operation(moc)
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
    
    // MARK: - Core data set up
    
    lazy var applicationStoresDirectory: NSURL? = {
        let fm = NSFileManager.defaultManager()
        
        if let dir = fm.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last as? NSURL {
            
            let url = dir.URLByAppendingPathComponent("Stores")
            
            if url.path != nil && (!fm.fileExistsAtPath(url.path!)) {
                var error:NSError? = nil
                fm.createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil, error: &error)
                
                if error != nil {
                    NSLog("unable to create directory for data stores")
                    return nil
                }
            }
    
            return url
        }
        
        return nil
        
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let url = NSBundle.mainBundle().URLForResource("Todo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL:url)!
    }()
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let coordinator:NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let storeURL = self.applicationStoresDirectory?.URLByAppendingPathComponent("Todo.sqlite")
    
        var error:NSError? = nil
        
        var options = [String:AnyObject]()
        
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true
        
        coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &error)
        
        if error != nil {
            NSLog("Unresolved error \(error!), \(error!.userInfo)")
        
            var fm = NSFileManager.defaultManager()
            if let path = storeURL?.path {
                if fm.fileExistsAtPath(path) {
                
                    fm.removeItemAtURL(storeURL!, error: &error)
                    
                    if error != nil {
                        NSLog("Failed to remove incompatible store")
                    
                    } else {
                        NSLog("Successfully removed incompatible store")
                    }
                }
            }
        
            coordinator .addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)
            
            if error != nil {
                NSLog("Unable to create store, \(error!.userInfo)")
            }
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext:NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        
        if coordinator == nil {
            return nil
        }
        
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator
        return moc
    }()
    
    lazy var privateManagedObjectContext:NSManagedObjectContext? = {
        let moc = self.managedObjectContext
        
        if moc == nil {
            return nil
        }
        
        let privateMoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateMoc.parentContext = moc!
        return privateMoc
    }()
}