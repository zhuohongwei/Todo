//
//  TodoItemsTableViewController.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 11/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import UIKit


private let TodoItemCellIdentifier = "TodoItemCell"

class TodoItemsTableViewController: UITableViewController {

    var todoItems:[[NSObject:AnyObject]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My Todo List"
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: TodoItemCellIdentifier)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("createTodoItem:"))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemCreatedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemDeletedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemToggleCompletedNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAllTodoItems()
    }

    func loadAllTodoItems() {
        TodoStore.sharedInstance.allTodoItems { (items, _) -> Void in
            if let allItems = items as? [[NSObject:AnyObject]] {
                self.todoItems.removeAll(keepCapacity: false)
                self.todoItems = self.todoItems + allItems
                self.tableView.reloadData()
            }
        }
    }
    
    func createTodoItem(sender:AnyObject) {
        var alert = UIAlertController(title: "New Todo Item", message: "Type a description", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            if let titleField = alert.textFields?.first as? UITextField {
                
                var title:String = titleField.text
                title = title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

                if countElements(title) > 0 {
                    TodoActions.create(title)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "What needs to be done?"
        })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countElements(todoItems)
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TodoItemCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        let item = todoItems[indexPath.row]
        
        let title = item["title"]! as String
        let createdAt = item["createdAt"]! as NSDate
        let completed = item["completed"]! as NSNumber
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = createdAt.descriptionWithLocale(NSLocale.currentLocale())
    
        if completed.boolValue {
            cell.accessoryType = .Checkmark
            
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let item = todoItems[indexPath.row]
            
            let itemId = item["itemId"]! as String
            TodoActions.delete(itemId)
            
            todoItems.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let item = todoItems[indexPath.row]
        let itemId = item["itemId"]! as String
        TodoActions.toggleCompleted(itemId)
    }
    
}
