//
//  TestRequestProcess.swift
//  HoxroCaseTracker
//
//  Created by Towhid on 5/17/16.
//  Copyright © 2016 Hoxro Limited, 207 Regent Street, London, W1B 3HN London, W1B 3HN. All rights reserved.
//

import Foundation
import CoreDataStack
import CoreNetworkStack

@objc(Transaction)
@objcMembers
public class Transaction: NSObject, TransactionProcessingProtocol{

    public required init(request: HttpWebRequest, parserType: Response.Type, memoryHandler: ((_ previous: [String: AnyObject]) -> [String: AnyObject])? = nil) {
        super.init()
        self.request = request
        self.parserType = parserType
        if let handler = memoryHandler{
            self.workingMemoryHandler = handler
        }
    }
    
    var _workingMemoryHandler: ((_ previous: [String: AnyObject]) -> [String: AnyObject]) = { (previous: [String: AnyObject]) -> [String: AnyObject] in
        var to: [String: AnyObject] = [String: AnyObject]()
        for (key, value) in previous{
            to[key] = value
        }
        return to
    }
    public var workingMemoryHandler: ((_ previous: [String: AnyObject]) -> [String: AnyObject]) {
        get{
            return _workingMemoryHandler
        }
        set{
            _workingMemoryHandler = newValue
        }
    }
    
    private var _parserType: Response.Type = Response.self
    public var parserType: Response.Type {
        get{
            return _parserType
        }
        set{
            _parserType = newValue
        }
    }
    
    private var _workingMemory: [String : AnyObject] = [String : AnyObject]()
    public var workingMemory: [String : AnyObject]{
        get{
            return _workingMemory
        }
    }
    
    public func addObjectToMemory(_ value: AnyObject, key: String) {
        _workingMemory[key] = value
    }
    
    public func copyObject(fromMemory memory: [String : AnyObject], key: String) {
        _workingMemory[key] = memory[key]
    }
    
    public func copyAll(_ from: [String : AnyObject]) {
        for (key, value) in from{
            _workingMemory[key] = value
        }
    }
    
    private weak var _linkedProcess: TransactionProcessingProtocol?
    public var linkedProcess: TransactionProcessingProtocol? {
        get{
            return _linkedProcess
        }
        set{
            _linkedProcess = newValue
        }
    }
    
    private var _request: HttpWebRequest!
    public var request: HttpWebRequest {
        get{
            return _request
        }
        set{
            _request = newValue
        }
    }
    
    public func execute(_ success: @escaping ((_ next: TransactionProcessingProtocol?, _ previousResponse: [NGObjectProtocol]?) -> Void), failed: @escaping ((_ abort: Bool, _ reason: Response) -> Void)) -> Void {
        NetworkActivity.sharedInstance().start()
        RemoteSession.default().sendMessage(request) { (data, response, error) -> Void in
            
            NetworkActivity.sharedInstance().stop()
            
            if error != nil{
                let reason = Response()
                reason.handleHttpResponse(response as? HTTPURLResponse, error: error as NSError?)
                failed(true, reason)
                return
            }
            
            if let res = response as? HTTPURLResponse, (res.statusCode == HttpStatusCode.ok.rawValue || res.statusCode == HttpStatusCode.created.rawValue){
                
                guard let xdata = data
                    else{
                        let reason = Response()
                        reason.handleHttpResponse(response as? HTTPURLResponse, error: error as NSError?)
                        failed(true, reason)
                        return
                }
                
                do{
                    if let info = try JSONSerialization.jsonObject(with: xdata, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                        print(info)
                        let parseInfo = self.parserType.init(info: info as [NSObject : AnyObject])
                        parseInfo?.handleHttpResponse(res, error: error as NSError?)
                        self.linkedProcess?.copyAll(self.workingMemoryHandler(self.workingMemory as [String: AnyObject]))
                        success(self.linkedProcess, [parseInfo!])
                    }
                    else if let info = try JSONSerialization.jsonObject(with: xdata, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray{
                        print(info)
                        var responseItems = [NGObject]()
                        for item in info as! [[NSObject : AnyObject]]{
                            let parseInfo = self.parserType.init(info: item)
                            parseInfo?.handleHttpResponse(res, error: error as NSError?)
                            responseItems.append(parseInfo!)
                        }
                        self.linkedProcess?.copyAll(self.workingMemoryHandler(self.workingMemory as [String: AnyObject]))
                        success(self.linkedProcess, responseItems)
                    }
                    else{
                        guard let info = NSString(data: xdata, encoding: String.Encoding.utf8.rawValue)
                            else{
                            self.linkedProcess?.copyAll(self.workingMemoryHandler(self.workingMemory as [String: AnyObject]))
                            success(self.linkedProcess, nil)
                            return
                        }
                        print(info)
                        let parseInfo = self.parserType.init(info: ["data":info] as [NSObject : AnyObject])
                        parseInfo?.handleHttpResponse(res, error: error as NSError?)
                        self.linkedProcess?.copyAll(self.workingMemoryHandler(self.workingMemory as [String: AnyObject]))
                        success(self.linkedProcess, [parseInfo!])
                    }
                }catch let error as NSError{
                    print("\(error.debugDescription)")
                    let reason = Response()
                    reason.handleHttpResponse(response as? HTTPURLResponse, error: error)
                    failed(true, reason)
                }
            }
            else{
                let reason = Response()
                reason.handleHttpResponse(response as? HTTPURLResponse, error: error as NSError?)
                failed(true, reason)
            }
            //
        }
    }
    
}
