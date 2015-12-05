//
//  TodoActions.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 12/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import Foundation

internal let TodoAction = "action"
internal let TodoItemTitle = "title"
internal let TodoItemId = "item_id"

internal let TodoActionCreate = "action_create"
internal let TodoActionDelete = "action_delete"
internal let TodoActionToggleCompleted = "action_toggle_completed"

class TodoActions {
    
    class func create(title:String) {
        Dispatcher.sharedInstance.dispatch([
            TodoAction: TodoActionCreate,
            TodoItemTitle: title
        ])
    }

    class func delete(itemId:String) {
        Dispatcher.sharedInstance.dispatch([
            TodoAction: TodoActionDelete,
            TodoItemId: itemId
        ])
    }
    
    class func toggleCompleted(itemId:String) {
        Dispatcher.sharedInstance.dispatch([
            TodoAction: TodoActionToggleCompleted,
            TodoItemId: itemId
        ])
    }
    
}


