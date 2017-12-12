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

@objc(TransactionStack)
@objcMembers
open class TransactionStack: NSObject, TransactionProcessorDelegate {
    
    fileprivate var processor: TransactionProcessor!
    fileprivate var callBack: ((_ received: [NGObjectProtocol]?) -> Void)?
    
    required public init(callBack: ((_ received: [NGObjectProtocol]?) -> Void)?) {
        super.init()
        self.callBack = callBack
        self.processor = TransactionProcessor(delegate: self, errorResponse: Response.self)
    }
    
    open func push(_ process: TransactionProcessingProtocol){
        self.processor.push(process: process)
    }
    
    open func commit(){
        self.processor.start()
    }
    
    open func cancel() {
        self.processor.abort()
    }
    
    open func processingDidFinished(_ processor: TransactionProcessor, finalResponse: [NGObjectProtocol]?) {
        guard let callBack = self.callBack else{
            return
        }
        callBack(finalResponse)
    }
    
    open func processingDidFailed(_ processor: TransactionProcessor, failedResponse: NGObjectProtocol) {
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
