//
//  Dispatcher.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 12/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import Foundation

typealias Payload = [NSObject: AnyObject]
typealias PayloadHandler = (Payload) -> ()

class Dispatcher {

    static let sharedInstance = Dispatcher()
    
    var callbacks = [PayloadHandler]()

    func dispatch(payload: Payload) {
        for callback in callbacks {
            callback(payload)
        }
    }
    
    func register(handler: PayloadHandler) {
        callbacks.append(handler)
    }
}