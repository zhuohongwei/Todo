//
//  TodoItem+CoreDataProperties.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 4/12/15.
//  Copyright © 2015 hw. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TodoItem {

    @NSManaged var itemId: String?
    @NSManaged var title: String?
    @NSManaged var completed: NSNumber?
    @NSManaged var createdAt: NSDate?

}
