//
//  AppDelegate.swift
//  Todo
//
//  Created by Zhuo Hong Wei on 11/4/15.
//  Copyright (c) 2015 hw. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        TodoStore.sharedInstance.registerWithDispatcher()
        
        let rootVC = TodoItemsTableViewController(style:.Plain)
        let rootNVC = UINavigationController(rootViewController: rootVC)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.backgroundColor = UIColor.whiteColor()
        window!.rootViewController = rootNVC
        window!.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }
}

