//
//  TodoItemVO.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 4/12/15.
//  Copyright © 2015 hw. All rights reserved.
//

import Foundation

struct TodoItemVO {

    let itemId: String
    let title: String
    let completed: Bool
    let createdAt: NSDate

    init?(todoItem: TodoItem) {
        guard let
            itemId = todoItem.itemId,
            title = todoItem.title,
            createdAt = todoItem.createdAt,
            completed = todoItem.completed?.boolValue else {
                return nil
        }

        self.itemId = itemId
        self.title = title
        self.completed = completed
        self.createdAt = createdAt
    }

}