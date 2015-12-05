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

    var todoItems = [TodoItemVO]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My Todo List"
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: TodoItemCellIdentifier)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("createTodoItem:"))

        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemCreatedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemDeletedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("loadAllTodoItems"), name: TodoItemToggleCompletedNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAllTodoItems()
    }

    func loadAllTodoItems() {
        TodoStore.sharedInstance.allTodoItems { (items, error) in

            guard let items = items as? [TodoItemVO] else {
                return
            }

            self.todoItems.removeAll()
            self.todoItems.appendContentsOf(items)
            self.tableView.reloadData()

        }
    }
    
    func createTodoItem(sender: AnyObject) {

        let alert = UIAlertController(
            title: "New Todo Item",
            message: "Type a description",
            preferredStyle: .Alert)

        alert.addTextFieldWithConfigurationHandler { field in
            field.placeholder = "What needs to be done?"
        }

        alert.addAction(UIAlertAction(title: "Add", style: .Default, handler: { _ in

            if let titleField = alert.textFields?.first {

                guard let title = titleField.text else {
                    return
                }

                let trimmedTitle =
                    title.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

                if !trimmedTitle.isEmpty {
                    TodoActions.create(title)
                }

            }

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(TodoItemCellIdentifier, forIndexPath: indexPath)
        let item = todoItems[indexPath.row]

        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.createdAt.descriptionWithLocale(NSLocale.currentLocale())
    
        if item.completed {
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

            TodoActions.delete(item.itemId)
            
            todoItems.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let item = todoItems[indexPath.row]

        TodoActions.toggleCompleted(item.itemId)

    }
    
}
