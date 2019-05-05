//
//  Response.swift
//  NoiBox
//
//  Created by Towhid on 5/3/16.
//  Copyright © 2016 Secure Link Services AG (http://m.towhid.islam@gmail.com). All rights reserved.
//

import UIKit
import CoreDataStack

@objc(Response)
@objcMembers
open class Response: NGObject {
    
    public static let HttpStatusUnauthorizedAccessNotification = Notification.Name("HttpStatusUnauthorizedAccessNotification")
    
    required override public init(){
        super.init()
    }
    
    required override public init!(info: [AnyHashable: Any]!) {
        super.init(info: info)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var uuid: NSObject = UUID().uuidString as NSObject
    public var succeed: Bool{
        return (code.rawValue == HttpStatusCode.ok.rawValue || code.rawValue == HttpStatusCode.created.rawValue)
            ? true
            : false
    }
    public var code: HttpStatusCode = HttpStatusCode.ok {
        didSet{
            if code.rawValue == HttpStatusCode.unauthorized.rawValue  {
                NotificationCenter.default.post(name: Response.HttpStatusUnauthorizedAccessNotification, object: nil)
            }
        }
    }
    public var error: NSString?
    public var error_description: NSString?
    public var errorMessage: NSString?
    public var message: NSString?
    public var fieldErrors: [FieldError] = [FieldError]()
    
    func handleHttpResponse(_ response: URLResponse?, error: NSError?){
        if let res = response as? HTTPURLResponse{
            code = HttpStatusCode(rawValue: res.statusCode)!
        }
        if let err = error {
            errorMessage = err.debugDescription as NSString?
        }
    }
    
    override open func updateValue(_ value: Any!, forKey key: String!) {
        if key == "fieldErrors"{
            if value is NSArray {
                let vals = value as! [[String:AnyObject]]
                for item in vals {
                    fieldErrors.append(FieldError(info: item))
                }
            }
        }
        else{
            super.updateValue(value, forKey: key)
        }
    }
}

@objc(FieldError)
@objcMembers
open class FieldError: NGObject {
    public var objectName: NSString?
    public var field: NSString?
    public var message: NSString?
}
