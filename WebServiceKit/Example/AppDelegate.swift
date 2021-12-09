//
//  AppDelegate.swift
//  Example
//
//  Created by Towhid Islam on 11/17/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit
import CoreNetworkStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var badgeCounter = NTLocalNotificationCenter.resolveLocalNotification(ofType: "DownloadAction")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Local Notification
        NTLocalNotificationCenter.registerLocalNotification(application: application, launchOptions: launchOptions )
        NetworkActivity.sharedInstance().activateReachabilityObserver(withHostAddress: "www.google.com")
        return true
    }

    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        badgeCounter.handleLocalNotification(notification: notification, application: application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        badgeCounter.clearBadgeNumber(application: application)
        NetworkActivity.sharedInstance().activateReachabilityObserver(withHostAddress: "www.google.com")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NetworkActivity.sharedInstance().deactivateReachabilityObserver()
    }
}

