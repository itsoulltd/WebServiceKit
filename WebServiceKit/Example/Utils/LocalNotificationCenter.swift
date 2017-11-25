//
//  LocalNotificationCenter.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 5/25/15.
//  Copyright (c) 2015 Towhid (Selise.ch). All rights reserved.
//

import UIKit
import CoreDataStack

public class LocalNotificationCenter: NSObject {
    
    private struct localSharedObjects{
        static var objectCache: NSMutableDictionary = NSMutableDictionary()
    }
    
    class func registerLocalNotification(application: UIApplication, launchOptions: [UIApplicationLaunchOptionsKey: Any]?){
        //
        if #available(iOS 8.0, *) {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge], categories: nil))
        } else if #available(iOS 10, *){
            //
        }
        else {
            // Fallback on earlier versions
        }
        if let launchOpt = launchOptions as NSDictionary?{
            if let _ = launchOpt.object(forKey: UIApplicationLaunchOptionsKey.localNotification) as? UILocalNotification {
                application.applicationIconBadgeNumber = 0
            }
        }
    }
    
    private struct SharedMonitor{
        static var monitor = NTMonitor()
    }
    
    private class func initLocalNotification(ofType type: String) -> NTLocalNotification{
        //
        let instance = NTLocalNotification(actionType: type)
        SharedMonitor.monitor.registerMonitoring(type: type, frequency: NTFrequency.Allways)
        return instance
    }
    
    class func resolveLocalNotification(ofType type: String) -> NTLocalNotification{
        //
        if let cached = localSharedObjects.objectCache.object(forKey: type) as? NTLocalNotification{
            return cached
        }
        else{
            let newlyCreated = LocalNotificationCenter.initLocalNotification(ofType: type)
            localSharedObjects.objectCache.setObject(newlyCreated, forKey: type as NSCopying)
            return newlyCreated
        }
    }
    
    class func replaceMonitoring(forType: String, frequency: NTFrequency, expRate: Double = 1.0, multiplier: Double = 1.0, maxLimit: Double = 12.0, startDate: NSDate? = nil){
        //
        SharedMonitor.monitor.unregisterMonitoring(type: forType)
        SharedMonitor.monitor.registerMonitoring(type: forType, frequency: frequency, expRate: expRate, multiplier: multiplier, maxLimit: maxLimit, startDate: startDate)
    }
    
    class func stopMonitoring(forType: String){
        SharedMonitor.monitor.unregisterMonitoring(type: forType)
        localSharedObjects.objectCache.removeObject(forKey: forType)
    }
    
    class func clearBadgeNumber(forType type: String, application: UIApplication){
        let cache = LocalNotificationCenter.resolveLocalNotification(ofType: type)
        cache.clearBadgeNumber(application: application)
    }
    
    class func handleLocalNotification(notification: UILocalNotification, application: UIApplication, completionHandler: ((_ type: String, _ badgeNumber: Int) -> Void)? = nil){
        //
        if (notification.alertAction != nil){
            let cache = LocalNotificationCenter.resolveLocalNotification(ofType: notification.alertAction!)
            cache.handleLocalNotification(notification: notification, application: application, completionHandler: completionHandler)
        }
    }
    
    class func stepUpBadgeNumber(forType type: String, message: String? = nil){
        let cache = LocalNotificationCenter.resolveLocalNotification(ofType: type)
        cache.stepUpBadgeNumber(message: message)
    }
    
    class func stepDownBadgeNumber(forType type: String, message: String? = nil){
        let cache = LocalNotificationCenter.resolveLocalNotification(ofType: type)
        cache.stepDownBadgeNumber(message: message)
    }
    
    fileprivate class func scheduleNotification(actionType: String,message: String? = nil, counter: Int){
        //
        if SharedMonitor.monitor.shouldFire(type: actionType, nowDate: NSDate()){
            let local = UILocalNotification()
            local.fireDate = NSDate().addingTimeInterval(0.3) as Date
            local.timeZone = NSTimeZone.system
            local.alertBody = message
            local.soundName = nil
            local.applicationIconBadgeNumber = counter
            local.alertAction = actionType
            UIApplication.shared.scheduleLocalNotification(local)
        }
    }
   
}

public class NTLocalNotification: NGObject{
    
    private var actionType: NSString!
    var ActionType: String {
        return actionType as String
    }
    private var badgeNumber: NSNumber = 0
    
    init(actionType: String) {
        super.init()
        self.actionType = actionType as NSString
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func clearBadgeNumber(application: UIApplication){
        //
        if badgeNumber == 0{
            application.applicationIconBadgeNumber = badgeNumber.intValue
        }
    }
    
    func handleLocalNotification(notification: UILocalNotification, application: UIApplication, completionHandler: ((_ type: String, _ badgeNumber: Int) -> Void)? = nil){
        //
        if notification.alertAction! == ActionType{
            application.applicationIconBadgeNumber = badgeNumber.intValue
            if let handler = completionHandler{
                handler(ActionType, badgeNumber.intValue)
            }
        }
    }
    
    func stepUpBadgeNumber(message: String? = nil){
        var number = badgeNumber.intValue
        number += 1
        badgeNumber = NSNumber(value: number)
        LocalNotificationCenter.scheduleNotification(actionType: ActionType, message: message, counter: badgeNumber.intValue)
    }
    
    func stepDownBadgeNumber(message: String? = nil){
        var number = badgeNumber.intValue
        number -= 1
        badgeNumber = NSNumber(value: number)
        LocalNotificationCenter.scheduleNotification(actionType: actionType as String, message: message, counter: badgeNumber.intValue)
    }
}

