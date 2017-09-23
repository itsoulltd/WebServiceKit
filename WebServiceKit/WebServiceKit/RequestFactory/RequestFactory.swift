//
//  RequestFactory.swift
//  Jamahook
//
//  Created by Towhid on 11/4/15.
//  Copyright © 2015 Secure Link Services AG (http://m.towhid.islam@gmail.com). All rights reserved.
//

import Foundation
import CoreDataStack
import CoreNetworkStack

public struct RequestMetaKeys {
    static let ActiveLive = "ActiveLive"
    static let PingURL = "PingUrl"
    static let LiveURL = "LiveUrl"
    static let StagingURL = "StagingUrl"
    static let ReferrerKey = "Referer"
    static let URLScheme = "URLScheme"
}

@objc(RequestMetadata)
open class RequestMetadata: NGObject{
    
    var httpMethod: HTTP_METHOD!
    var contentType: Application_ContentType!
    var routePath: NSString?
    var pathParams: [String]?
    
    open override func updateValue(_ value: Any!, forKey key: String!) {
        if key == "httpMethod"{
            if ((value as! String).lowercased() == "post"){
                httpMethod = POST
            }
            else{
                httpMethod = GET
            }
        }
        else if key == "contentType"{
            if ((value as! String).lowercased() == "json"){
                contentType = Application_JSON
            }
            else if ((value as! String).lowercased() == "multipart"){
                contentType = Application_Multipart_FormData
            }
            else{
                contentType = Application_Form_URLEncoded
            }
        }
        else if(key == "pathParams"){
            if value is NSArray{
                pathParams = (value as! NSArray) as? [String]
            }
        }
        else{
            super.updateValue(value, forKey: key)
        }
    }
    
    open override func serializeValue(_ value: Any!, forKey key: String!) -> Any! {
        if key == "httpMethod"{
            if httpMethod == POST{
                return "post" as AnyObject!
            }
            else{
                return "get" as AnyObject!
            }
        }
        else if key == "contentType"{
            if contentType == Application_JSON{
                return "json" as AnyObject!
            }
            else if contentType == Application_Multipart_FormData{
                return "multipart" as AnyObject!
            }
            else {
                return "urlencoded" as AnyObject!
            }
        }
        else if key == "pathParams"{
            if let pathParams = self.pathParams{
                return pathParams as NSArray
            }else{
                return nil
            }
        }
        else{
            return super.serializeValue(value, forKey: key) as AnyObject!
        }
    }
    
}

@objc(RequestFactory)
open class RequestFactory: NSObject{
    
    var propertyList: PropertyList!
    
    public required init(configFileName fileName: String) {
        super.init()
        propertyList = PropertyList(fileName: fileName, directoryType: FileManager.SearchPathDirectory.documentDirectory, dictionary: true)
    }
    
    public final func updateProperty(_ value: AnyObject, forKey key: String){
        propertyList.addItem(toCollection: value, forKey: key as NSCopying!)
        print("Updated key : \(getProperty(forKey: key))")
        propertyList.saveBackground()
    }
    
    public final func getProperty(forKey key: String) -> AnyObject{
        return propertyList.item(forKey: key as NSCopying!) as AnyObject
    }
    
    open func httpReferrerHeaderValue() -> [String]{
        let str = getProperty(forKey: "Referer") as! String
        return [str]
    }
    
    open func isLiveUrlActive() -> Bool{
        let isLive = getProperty(forKey: "ActiveLive") as! Bool
        return isLive
    }
    
    open func activeURL() -> URL{
        let baseUrlStr = activeURLString()
        let url = URL(string: baseUrlStr)!
        return url
    }
    
    open func activeURLString() -> String{
        let activeUrl = isLiveUrlActive() ? "LiveUrl" : "StagingUrl"
        let baseUrlStr = getProperty(forKey: activeUrl) as! String
        return baseUrlStr
    }
    
    open func pingURLString() -> String{
        let url = getProperty(forKey: "PingUrl") as! String
        return url
    }
    
    public final func validateUrlStr(_ urlStr: String) -> String{
        let uNSStr = urlStr as NSString
        //let result = uNSStr.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let result = uNSStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)
        return result!
    }
    
    public final func metadata(forKey key: String) -> RequestMetadata?{
        if let meta = getProperty(forKey: key) as? NSDictionary{
            let metadata = RequestMetadata(info: meta as! [AnyHashable: Any])
            return metadata
        }
        return nil
    }
    
    open func requestURL(forKey key: String) -> URL?{
        if let metadata = metadata(forKey: key){
            var validated: String = activeURLString()
            if let routePath = metadata.routePath{
                validated = "\(validated)/\(routePath)"
            }
            if let pathParams = metadata.pathParams{
                let combined = pathParams.joined(separator: "/")
                validated = "\(validated)/\(combined)"
            }
            return URL(string: validateUrlStr(validated))
        }
        return nil
    }
    
    open func request(forKey key: String, classType: HttpWebRequest.Type = HttpWebRequest.self) -> HttpWebRequest?{
        if let metadata = metadata(forKey: key){
            var request: HttpWebRequest? = nil
            if let routePath = metadata.routePath{
                let validated = validateUrlStr("\(activeURLString())/\(routePath)")
                request = classType.init(baseUrl: validated, method: metadata.httpMethod, contentType: metadata.contentType)
            }
            else{
                request = classType.init(baseUrl: activeURLString(), method: metadata.httpMethod, contentType: metadata.contentType)
            }
            if let pathParams = metadata.pathParams{
                request?.pathComponent = pathParams
            }
            request?.requestHeaderFields.addValues(httpReferrerHeaderValue(), forKey: "Referer")
            return request
        }
        return nil
    }
    
}
