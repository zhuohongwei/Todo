//
//  TodoItem.h
//  Todo
//
//  Created by Zhuo Hong Wei on 11/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TodoItem : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * itemId;
@property (nonatomic, retain) NSNumber * completed;

@end
