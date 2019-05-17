//
//  TransactionStack.swift
//  HoxroCaseTracker
//
//  Created by Towhid Islam on 1/13/17.
//  Copyright © 2017 Hoxro Limited, 207 Regent Street, London, W1B 3HN London. All rights reserved.
//
import UIKit
import CoreDataStack
import CoreNetworkStack

public enum TransactionStackState: Int{
    case None, Running, Finished, Failed, Canceled
}

@objc(TransactionStack)
@objcMembers
open class TransactionStack: NSObject, TransactionProcessorDelegate {
    
    fileprivate var processor: TransactionProcessor!
    fileprivate var callBack: ((_ received: [NGObjectProtocol]?) -> Void)?
    
    private var _status: TransactionStackState = .None
    public var status: TransactionStackState{
        get{
            return _status
        }
    }
    
    public required override init() {
        super.init()
        self.processor = TransactionProcessor(delegate: self, errorResponse: Response.self)
    }
    
    public convenience init(callBack: ((_ received: [NGObjectProtocol]?) -> Void)?) {
        self.init()
        self.callBack = callBack
    }
    
    open func push(_ process: TransactionProcessingProtocol){
        if status == .Running {
            return
        }
        self.processor.push(process: process)
    }
    
    open func commit(reverse inOrder: Bool = false, callBack: ((_ received: [NGObjectProtocol]?) -> Void)? = nil){
        if status == .Running {
            return
        }
        self.callBack = callBack
        if inOrder {
            self.processor.reverse()
        }
        _status = .Running
        self.processor.start()
    }
    
    open func cancel() {
        if status == .Running {
            _status = .Canceled
            self.processor.abort()
        }
    }
    
    open func processingDidFinished(_ processor: TransactionProcessor, finalResponse: [NGObjectProtocol]?) {
        _status = .Finished
        guard let callBack = self.callBack else{
            return
        }
        callBack(finalResponse)
    }
    
    open func processingDidFailed(_ processor: TransactionProcessor, failedResponse: NGObjectProtocol) {
        _status = .Failed
        guard let callBack = self.callBack else{
            return
        }
        callBack([failedResponse])
    }
    
    open func processingWillStart(_ processor: TransactionProcessor, forProcess process: TransactionProcessingProtocol) {
        //TODO
    }
    
    open func processingDidEnd(_ processor: TransactionProcessor, forProcess process: TransactionProcessingProtocol) {
        //TODO
    }
}
