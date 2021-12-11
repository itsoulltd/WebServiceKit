# WebServiceKit

### RequestQueue api:
    func enqueueRequest(_ capsul: HttpWebRequest) -> Void
    func enqueueRequest(_ capsul: HttpWebRequest, progressListener: ProgressListener?)
    func cancelable(_ capsul: HttpWebRequest) -> Bool
    func cancelRequest(_ capsul: HttpWebRequest) -> Void
    
    //How to Initialized a queue:
    var config = RequestQueueConfiguration(identifier: "viewDownloadSynch", info: [RequestQueueConfiguration.Keys.MaxTryCount:2])
    var downloadQ = DownloadQueue(configuration: config)
    downloadQ.restoreState()  //If there are any previoud download didn't finished.
    
    //Now create a WebRequest object
    let webReq = HttpWebRequest(baseUrl: "http://example.com/img/food.jpg")
    downloadQ.enqueueRequest(webReq!, progressListener: nil)
    
    //To cancel ongoing WebRequest
    downloadQ.cancelRequest(webReq!)