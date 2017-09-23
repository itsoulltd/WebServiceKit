//
//  GenericSynchronizer.swift
//  FlipMobNewGen
//
//  Created by Towhid on 2/4/15.
//  Copyright (c) 2015 http://m.towhid.islam@gmail.com/. All rights reserved.
//

import UIKit
import CoreDataStack
import CoreNetworkStack

@objc(RequestQueueDelegate)
public protocol RequestQueueDelegate{
    func synchronizationSucceed(_ forRequest: HttpWebRequest?, incomming: Data) -> Void
    func synchronizationFailed(_ forRequest: HttpWebRequest?, error: NSError?) -> Void
    @objc optional func downloadSucceed(_ forRequest: HttpWebRequest?, saveUrl: URL) -> Void
    @objc optional func progressListener(_ forRequest: HttpWebRequest?) -> ProgressListener
}

@objc(ProgressListener)
public protocol ProgressListener{
    func progressUpdate(_ value: CGFloat) -> Void;
    @objc optional func progressStart() -> Void;
    @objc optional func progressEnd() -> Void;
}

@objc(ContentDelegateImpl)
open class ContentDelegateImpl: NGObject, ContentDelegate {
    
    weak var listener: ProgressListener?
    
    open func progressHandler(_ handler: ContentHandler!, didFailedWithError error: Error!) {
        listener?.progressEnd!()
    }
    
    open func progressHandler(_ handler: ContentHandler!, uploadPercentage percentage: Float) {
        if percentage <= 2.0{
            listener?.progressStart!()
        }
        
        let pro: CGFloat = CGFloat(percentage/100)
        listener?.progressUpdate(pro)
        
        if (handler.totalByteRW >= handler.totalBytesExpectedToRW){
            listener?.progressEnd!()
        }
    }
    
    open func progressHandler(_ handler: ContentHandler!, downloadPercentage percentage: Float) {
        progressHandler(handler, uploadPercentage: percentage)
    }
    
    deinit{
        print("deinit :: \(self.description)")
    }
}

@objc(RequestQueueConfiguration)
open class RequestQueueConfiguration: NGObject {
    //Hello I do not Have Properties 😜, but have keys
    struct Keys {
        static let MaxTryCount = "maxTryCount"
        static let EnergyStateEnabled = "energyState"
    }
    
    var identifier: NSString!
    
    init(identifier: NSString, info: NSDictionary){
        super.init(info: info as! [AnyHashable: Any])
        self.identifier = identifier
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

@objc(Tracker)
open class Tracker: NGObject {
    
    var guid: NSString!
    var orderIndex: NSNumber!
    var request: HttpWebRequest?
    var delegate: ContentDelegateImpl?
    var maxTryCount: NSNumber = 1
    var tryCount: NSNumber = 0
    
    deinit{
        print("deinit :: \(self.description)")
    }
    
    override open func updateValue(_ value: Any!, forKey key: String!) {
        if key == "request"{
            if value is NSDictionary{
                let info: NSDictionary = (value as! NSDictionary)
                let allKeys = info.allKeys as NSArray
                if allKeys.contains("localFileURL"){
                    request = HttpFileRequest(info: info as! [AnyHashable: Any])
                }else{
                    request = HttpWebRequest(info: info as! [AnyHashable: Any])
                }
            }else{
                super.updateValue(value, forKey: key)
            }
        }
        else if key == "delegate"{
            if value is NSDictionary{
                delegate = nil
            }else{
                super.updateValue(value, forKey: key)
            }
        }else{
            super.updateValue(value, forKey: key)
        }
    }
    
    open override func serializeValue(_ value: Any!, forKey key: String!) -> Any! {
        return super.serializeValue(value, forKey: key) as AnyObject!
    }
    
    ///Ascending order
    class func sort(_ list: [Tracker]) -> [Tracker]{
        let sorted = list.sorted { (objA, objB) -> Bool in
            return objA.orderIndex.intValue < objB.orderIndex.intValue
        }
        return sorted
    }
}

@objc(RequestQueue)
public protocol RequestQueue{
    func enqueueRequest(_ capsul: HttpWebRequest) -> Void
    func enqueueRequest(_ capsul: HttpWebRequest, progressListener: ProgressListener?)
    func cancelable(_ capsul: HttpWebRequest) -> Bool
    func cancelRequest(_ capsul: HttpWebRequest) -> Void
}

@objc(BaseRequestQueue)
open class BaseRequestQueue: NSObject, RequestQueue {
    
    /***************************************THIS IS A GRAY AREA********************************************/
    
    func addCompletionHandler(_ identifier: String, completionHandler: @escaping () -> Void){
        self.session.addCompletionHandler(completionHandler, forSession: identifier)
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    
    init(configuration: RequestQueueConfiguration){
        super.init()
        self.configuration = configuration
        if let isEnabled = (configuration.value(forKey: RequestQueueConfiguration.Keys.EnergyStateEnabled) as AnyObject).boolValue{
            if isEnabled{
                self.session = EnergyStateSession.default()
            }
        }
        if session == nil{
            self.session = RemoteSession.default()
        }
    }
    
    deinit{
        print("deinit :: \(self.description)")
    }
    
    func activateInternetReachability(){
        //register for NetworkActivity's notification
        NotificationCenter.default.addObserver(self, selector: #selector(BaseRequestQueue.internetReachability(_:)), name: NSNotification.Name.InternetReachable, object: nil)
    }
    
    func deactivateInternetReachability(){
        //unregister from Notification Center
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.InternetReachable, object: nil)
    }
    
    @objc func internetReachability(_ notification: Notification){
        //
        if let userInfo = notification.userInfo as NSDictionary?{
            if let isReachable = userInfo.object(forKey: kInternetReachableKey) as? NSNumber{
                if isReachable.boolValue{
                    //now reachable
                    print("Internet Now available For GenericSynchronization")
                    kickStart()
                }
                else{
                    //not reachable
                    print("Internet Disconnect For GenericSynchronization")
                }
            }
        }
    }
    
    fileprivate var session: RemoteSession!
    fileprivate var requestQueue = Queue()
    fileprivate var runningQueue = Queue()
    fileprivate var cancelableContainer = NSMutableDictionary(capacity: 7)
    fileprivate let lock = NSLock()
    weak var delegate: RequestQueueDelegate?
    fileprivate var configuration: RequestQueueConfiguration!
    
    var networkReachable: Bool{
        return (NetworkActivity.sharedInstance() as AnyObject).isInternetReachable()
    }
    
    fileprivate func enqueueTracker(_ capsul: HttpWebRequest) -> Tracker?{
        let tracker = Tracker()
        tracker.request = capsul
        if let maxCount = configuration.value(forKey: RequestQueueConfiguration.Keys.MaxTryCount) as? NSNumber{
            tracker.maxTryCount = maxCount
        }
        requestQueue.enqueue(tracker)
        return tracker
    }
    
    fileprivate func enqueueTracker(_ capsul: HttpWebRequest, progressListener: ProgressListener?) -> Tracker? {
        if let tracker = self.enqueueTracker(capsul){
            if let _ = progressListener{
                tracker.delegate = ContentDelegateImpl()
                tracker.delegate?.listener = progressListener
            }
            return tracker
        }
        return nil
    }
    
    open func enqueueRequest(_ capsul: HttpWebRequest) {
        let _ = enqueueTracker(capsul)
        kickStart()
    }
    
    open func enqueueRequest(_ capsul: HttpWebRequest, progressListener: ProgressListener?) {
        let _ = enqueueTracker(capsul, progressListener: progressListener)
        kickStart()
    }
    
    open func cancelable(_ capsul: HttpWebRequest) -> Bool {
        if cancelableContainer.count <= 0{
            return false
        }
        if let _ = cancelableContainer.object(forKey: capsul.hash){
            return true
        }
        else{
            return false
        }
    }
    
    open func cancelRequest(_ capsul: HttpWebRequest) {
        //println("request hash \(capsul.hash)")
        if let taskObj = cancelableContainer.object(forKey: capsul.hash){
            if taskObj is RemoteTask{
                let task = taskObj as! RemoteTask
                task.cancelTask()
                removeTask(capsul)
            }
        }else{
            let hashValue = capsul.hash
            cancelableContainer.setObject(capsul, forKey: hashValue as NSCopying)
        }
    }
    
    fileprivate final func preCancelCheck(_ request: HttpWebRequest?) -> Bool{
        var isCancelable = false
        guard let capsul = request else{
            return isCancelable
        }
        if let taskObj = cancelableContainer.object(forKey: capsul.hash){
            isCancelable = (taskObj is RemoteTask) ? false : true
        }
        if isCancelable{
            removeTask(capsul)
        }
        return isCancelable
    }
    
    public final func kickStart(){
        //when running queue is empty, means nothing is running
        lock.lock()
        if runningQueue.isEmpty() == true{
            execute()
        }
        lock.unlock()
    }
    
    fileprivate func addTask(_ task: RemoteTask, forTracker: Tracker){
        if let request = forTracker.request{
            let hashValue = request.hash
            forTracker.maxTryCount = 1
            forTracker.tryCount = 1
            cancelableContainer.setObject(task, forKey: hashValue as NSCopying)
        }
    }
    
    fileprivate func removeTask(_ forRequest: HttpWebRequest?){
        if let request = forRequest{
            cancelableContainer.removeObject(forKey: request.hash)
        }
    }
    
    fileprivate func execute(){
        if !networkReachable{
            return
        }
        if let tracker = requestQueue.dequeue() as? Tracker{
            if preCancelCheck(tracker.request){
                execute()
            }
            else{
                runningQueue.enqueue(tracker)
                NetworkActivity.sharedInstance().start()
                let task = session.sendUtilityMessage(tracker.request, onCompletion: { (data, response, error) -> Void in
                    NetworkActivity.sharedInstance().stop()
                    self.removeTask(tracker.request)
                    self.onCompletion(data as AnyObject!, response: response, error: error as NSError!)
                })
                addTask(task!, forTracker: tracker)
            }
        }
    }
    
    fileprivate func onCompletion(_ data: AnyObject!, response: URLResponse!, error: NSError!){
        if (error != nil){
            self.whenFailed(error)
        }
        else{
            if let httpResponse = response as? HTTPURLResponse{
                if (httpResponse.statusCode == HttpStatusCode.ok.rawValue
                    || httpResponse.statusCode == HttpStatusCode.created.rawValue){
                        self.whenSucceed(data)
                }else{
                    self.whenFailed(error)
                }
            }
            else{
                self.whenSucceed(data)
            }
        }
        //Chaining the execution
        self.execute()
    }
    
    fileprivate func whenFailed(_ error: NSError!){
        //print("\(NSStringFromClass(type(of: self))) -> is running on \(String(cString: DISPATCH_CURRENT_QUEUE_LABEL.label))")
        if (error != nil) {
            print(error.debugDescription)
        }
        if let tracker = self.runningQueue.dequeue() as? Tracker{
            tracker.tryCount = NSNumber(value: tracker.tryCount.intValue + 1 as Int)
            if tracker.tryCount.intValue <= tracker.maxTryCount.intValue{
                self.requestQueue.enqueue(tracker)
            }
            else{
                self.delegate?.synchronizationFailed(tracker.request, error: error)
            }
        }
    }
    
    fileprivate func whenSucceed(_ data: AnyObject!){
        print(data)
        //print("\(NSStringFromClass(type(of: self))) -> is running on \(String(cString: DISPATCH_CURRENT_QUEUE_LABEL.label))")
        if let tracker = self.runningQueue.dequeue() as? Tracker{
            if data is NSData{
                self.delegate?.synchronizationSucceed(tracker.request, incomming: data as! Data)
            }
            else if data is NSURL{
                if let downloadSucceed = self.delegate?.downloadSucceed{
                    downloadSucceed(tracker.request, data as! URL)
                }
            }
        }
    }
    
}

/// 👉 Don't use use PersistableSynchronizer(or any subclass) from background thread.
/// this class is not thread safe. Calling from other then Main Thread might causes crash.
@objc(SavableRequestQueue)
open class SavableRequestQueue: BaseRequestQueue {
    
    fileprivate var identifier: String!
    fileprivate var orderIndex: Int = -1
    fileprivate var manager: PropertyList!
    
    override init(configuration: RequestQueueConfiguration){
        super.init(configuration: configuration)
        self.identifier = configuration.identifier as String
        //
        manager = PropertyList(fileName: "\(identifier)_synchronizer_queue", directoryType: FileManager.SearchPathDirectory.documentDirectory, dictionary: true)
        if let order = manager.item(forKey: identifier as NSCopying!) as? NSNumber{
            orderIndex = order.intValue
        }
        NotificationCenter.default.addObserver(self, selector: #selector(SavableRequestQueue.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    convenience init(configuration: RequestQueueConfiguration, remoteSession: RemoteSession){
        self.init(configuration: configuration)
        self.session = remoteSession
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc func applicationDidEnterBackground(_ notification: Notification){
        print("\(NSStringFromClass(type(of: self))) -> applicationDidEnterBackground Called")
        saveState()
    }
    
    fileprivate override func enqueueTracker(_ capsul: HttpWebRequest) -> Tracker?{
        let tracker = Tracker()
        tracker.guid = UUID().uuidString as NSString!
        tracker.request = capsul
        if let maxCount = configuration.value(forKey: RequestQueueConfiguration.Keys.MaxTryCount) as? NSNumber{
            tracker.maxTryCount = maxCount
        }
        requestQueue.enqueue(tracker)
        saveState(tracker)
        return tracker
    }
    
    fileprivate func saveState(_ tracker: Tracker){
        orderIndex += 1
        let newIndex = orderIndex
        tracker.orderIndex = newIndex as NSNumber!
        manager.addItem(toCollection: NSNumber(value: newIndex as Int), forKey: identifier as NSCopying!)
        let archivedTracker = NSKeyedArchiver.archivedData(withRootObject: tracker)
        manager.addItem(toCollection: archivedTracker, forKey: tracker.guid)
    }
    
    fileprivate func removeState(_ tracker: Tracker){
        manager.removeItemFromCollection(forKey: tracker.guid)
    }
    
    fileprivate func temporaryQueue() -> Queue{
        let collection = manager.readOnlyCollection() as! NSDictionary
        let queue = Queue()
        let allKeys = collection.allKeys as! [String]
        var trackers = [Tracker]()
        for key in allKeys{
            if key == identifier{
                continue
            }
            let data = collection.object(forKey: key) as! Data
            let tracker = NSKeyedUnarchiver.unarchiveObject(with: data) as! Tracker
            trackers.append(tracker)
        }
        let commends = Tracker.sort(trackers)
        for commend in commends{
            queue.enqueue(commend)
        }
        return queue
    }
    
    fileprivate func restoreQueue(from tempQueue: Queue){
        if (tempQueue.isEmpty() == true){
            return
        }
        //very complex senarios
        if requestQueue.isEmpty() {
            requestQueue = tempQueue
        }
        else{
            while(tempQueue.isEmpty() == false){
                requestQueue.enqueue(tempQueue.dequeue())
            }
        }
        //complex end
    }
    
    fileprivate func restoreState(){
        //New Implementation.
        let _queue = temporaryQueue()
        restoreQueue(from: _queue)
        //thats it.
    }
    
    fileprivate func saveState(){
        //New Implementation.
        if manager != nil{
            if (manager.save() == true){
                print("\(NSStringFromClass(type(of: self))) -> Manager last order index = \(orderIndex)")
            }
        }
    }
    
    fileprivate func reconstructProgressHandlerFor(_ tracker: Tracker){
        if tracker.delegate == nil{
            tracker.delegate = ContentDelegateImpl()
            if let progressListener = self.delegate?.progressListener{
                tracker.delegate?.listener = progressListener(tracker.request)
            }
        }
    }
    
    fileprivate override func execute(){
        if !networkReachable{
            return
        }
        if let tracker = requestQueue.dequeue() as? Tracker{
            if preCancelCheck(tracker.request){
                execute()
            }
            else{
                runningQueue.enqueue(tracker)
                NetworkActivity.sharedInstance().start()
                let task = session.sendUtilityMessage(tracker.request, onCompletion: { (data, response, error) -> Void in
                    NetworkActivity.sharedInstance().stop()
                    self.removeTask(tracker.request)
                    self.onCompletion(data as AnyObject!, response: response, error: error as NSError!)
                })
                addTask(task!, forTracker: tracker)
            }
        }
    }
    
    fileprivate override func whenFailed(_ error: NSError!){
        //print("\(NSStringFromClass(type(of: self))) -> is running on \(String(cString: DISPATCH_CURRENT_QUEUE_LABEL.label))")
        if (error != nil) {
            print(error.debugDescription)
        }
        if let tracker = self.runningQueue.dequeue() as? Tracker{
            tracker.tryCount = NSNumber(value: tracker.tryCount.intValue + 1 as Int)
            if tracker.tryCount.intValue <= tracker.maxTryCount.intValue{
                self.requestQueue.enqueue(tracker)
                self.saveState()
            }
            else{
                self.removeState(tracker)
                self.saveState()
                self.delegate?.synchronizationFailed(tracker.request, error: error)
            }
        }
    }
    
    fileprivate override func whenSucceed(_ data: AnyObject!){
        //print("\(NSStringFromClass(type(of: self))) -> is running on \(String(cString: DISPATCH_CURRENT_QUEUE_LABEL.label))")
        if let tracker = self.runningQueue.dequeue() as? Tracker{
            self.removeState(tracker)
            self.saveState()
            if data is NSData{
                self.delegate?.synchronizationSucceed(tracker.request, incomming: data as! Data)
            }
            else if data is NSURL{
                if let downloadSucceed = self.delegate?.downloadSucceed{
                    downloadSucceed(tracker.request, data as! URL)
                }
            }
        }
    }
    
}

/// 👉 Don't use use PersistableSynchronizer(or any subclass) from background thread.
/// this class is not thread safe. Calling from other then Main Thread might causes crash.
@objc(DownloadQueue)
open class DownloadQueue: SavableRequestQueue {
    
    fileprivate override func execute() {
        if !networkReachable{
            return
        }
        if let tracker = requestQueue.dequeue() as? Tracker{
            if preCancelCheck(tracker.request){
                execute()
            }
            else{
                runningQueue.enqueue(tracker)
                reconstructProgressHandlerFor(tracker)
                NetworkActivity.sharedInstance().start()
                let task = session.downloadContent(tracker.request, progressDelegate: tracker.delegate, onCompletion: { (url, response, error) -> Void in
                    NetworkActivity.sharedInstance().stop()
                    self.removeTask(tracker.request)
                    self.onCompletion(url as AnyObject!, response: response, error: error as NSError!)
                })
                addTask(task!, forTracker: tracker)
            }
        }
    }
    
}

/// 👉 Don't use PersistableSynchronizer(or any subclass) from background thread.
/// this class is not thread safe. Calling from other then Main Thread might causes crash.
@objc(UploadQueue)
open class UploadQueue: SavableRequestQueue {
    
    fileprivate override func execute() {
        if !networkReachable{
            return
        }
        if let tracker = requestQueue.dequeue() as? Tracker{
            if preCancelCheck(tracker.request){
                execute()
            }
            else{
                runningQueue.enqueue(tracker)
                if tracker.request is HttpFileRequest{
                    reconstructProgressHandlerFor(tracker)
                    NetworkActivity.sharedInstance().start()
                    let task = session.uploadContent(tracker.request as! HttpFileRequest, progressDelegate: tracker.delegate, onCompletion: { (data, response, error) -> Void in
                        //
                        NetworkActivity.sharedInstance().stop()
                        self.removeTask(tracker.request)
                        self.onCompletion(data as AnyObject!, response: response, error: error as NSError!)
                    })
                    addTask(task!, forTracker: tracker)
                }
                else{
                    super.execute()
                }
            }
        }
    }
    
}

/// 👉 Don't use PersistableSynchronizer(or any subclass) from background thread.
/// this class is not thread safe. Calling from other then Main Thread might causes crash.
@objc(UploadOnceQueue)
open class UploadOnceQueue: UploadQueue {
    
    fileprivate var backgroundModeActivated = false
    fileprivate var lastTracker: Tracker? {
        get{
            guard let unarchived = UserDefaults.standard.object(forKey: "CurrentTrackerKey") as? Data else{
                return nil
            }
            let tracker = NSKeyedUnarchiver.unarchiveObject(with: unarchived) as? Tracker
            return tracker
        }
        set{
            self.lastTracker = newValue
            if let nValue = newValue{
                let archived = NSKeyedArchiver.archivedData(withRootObject: nValue)
                UserDefaults.standard.set(archived, forKey: "CurrentTrackerKey")
                //NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    func applicationDidEnterBackground(){
        backgroundModeActivated = true
    }
    
    func applicationWillEnterForeground(){
        backgroundModeActivated = false
    }
    
    override func addCompletionHandler(_ identifier: String, completionHandler: @escaping () -> Void) {
        super.addCompletionHandler(identifier, completionHandler: completionHandler)
        applicationDidEnterBackground()
    }
    
    fileprivate func ignore(tracker: Tracker) -> Bool{
        if let lTracker = lastTracker{
            if tracker.guid == lTracker.guid{
                return true
            }
        }
        lastTracker = tracker
        return false
    }
    
    fileprivate override func execute() {
        if !networkReachable{
            return
        }
        if let tracker = requestQueue.dequeue() as? Tracker{
            if preCancelCheck(tracker.request){
                execute()
            }
            else{
                //Test
                if ignore(tracker: tracker){
                    execute()
                    return
                }
                //
                runningQueue.enqueue(tracker)
                if tracker.request is HttpFileRequest{
                    reconstructProgressHandlerFor(tracker)
                    NetworkActivity.sharedInstance().start()
                    let task = session.uploadContent(tracker.request as! HttpFileRequest, progressDelegate: tracker.delegate, onCompletion: { (data, response, error) -> Void in
                        NetworkActivity.sharedInstance().stop()
                        self.removeTask(tracker.request)
                        self.onCompletion(data as AnyObject!, response: response, error: error as NSError!)
                    })
                    addTask(task!, forTracker: tracker)
                }
                else{
                    super.execute()
                }
            }
        }
    }
    
}

