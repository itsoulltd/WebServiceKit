//
//  NTLocalNotification.swift
//  Example
//
//  Created by Towhid  on 5/4/19.
//  Copyright © 2019 Towhid Islam. All rights reserved.
//

import Foundation
import CoreDataStack

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
        NTLocalNotificationCenter.scheduleNotification(actionType: ActionType, message: message, counter: badgeNumber.intValue)
    }
    
    func stepDownBadgeNumber(message: String? = nil){
        var number = badgeNumber.intValue
        number -= 1
        badgeNumber = NSNumber(value: number)
        NTLocalNotificationCenter.scheduleNotification(actionType: actionType as String, message: message, counter: badgeNumber.intValue)
    }
}
