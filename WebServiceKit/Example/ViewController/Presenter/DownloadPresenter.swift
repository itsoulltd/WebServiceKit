//
//  DownloadPresenter.swift
//  Example
//
//  Created by Towhid Islam on 12/1/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit
import CoreDataStack
import CoreNetworkStack
import WebServiceKit
import FileSystemSDK

class DownloadPresenter: NGObject {
    
    var dataSource: [DownloadModel] = [DownloadModel]()
    @IBOutlet weak var tableView: DownloadTableView!
    var writeFile: File? = nil
    weak var downloader: DownloadQueue!
    var router: RouterProtocol?
    
    func configure(downloader: DownloadQueue, router: RouterProtocol) {
        self.downloader = downloader
        self.downloader.delegate = self
        
        tableView.presenter = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        self.router = router
    }
    
    func findModelFor(request: HttpWebRequest?) -> DownloadModel?{
        var find: DownloadModel?
        for model in dataSource{
            if model.request == request{
                find = model
                break
            }
        }
        return find
    }
    
    func insertModel(forRequest: HttpWebRequest?, progress: Progress?) {
        let dcm = DownloadModel(info: ["request":forRequest!])
        dcm?.progress = progress
        
        let lastIndex = dataSource.count
        dataSource.append(dcm!)
        
        DispatchQueue.main.async {
            self.tableView.insertRows(at: [IndexPath(row: lastIndex, section: 0)]
                , with: .top)
        }
    }
    
    func deleteModel(_ indexPath: IndexPath) {
        dataSource.remove(at: indexPath.row)
    }
    
    func route(_ info: DownloadModel) {
        self.router?.route(from: nil, info: info)
    }
    
}

extension DownloadPresenter: RequestQueueDelegate{
    
    //MARK: Utility Func
    
    func updateDownloadSavePath(forRequest: HttpWebRequest?, savePath: URL?) {
        if let model: DownloadModel = findModelFor(request: forRequest){
            model.savedUrl = savePath
        }
        NTLocalNotificationCenter.stepDownBadgeNumber(forType: "DownloadAction", message: "Download Complete")
    }
    
    //MARK: GenericSynchDelegate
    
    func requestDidSucceed(_ forRequest: HttpWebRequest?, incomming: Data) {
        //TODO
    }
    
    func requestDidFailed(_ forRequest: HttpWebRequest?, error: NSError?) {
        //TODO
    }
    
    func progressListener(_ forRequest: HttpWebRequest?) -> ProgressListener {
        let prog = Progress()
        if let request = forRequest{
            self.insertModel(forRequest: request, progress: prog)
        }
        return prog
    }
    
    func downloadSucceed(_ forRequest: HttpWebRequest?, saveUrl: URL) {
        let fileName = (forRequest?.baseUrl as NSString!).lastPathComponent
        let readFile = File(url: saveUrl)
        let imagesFolder = Folder(name: "Images", searchDirectoryType: FileManager.SearchPathDirectory.cachesDirectory)
        let writePath = imagesFolder.path()?.appendingPathComponent(fileName)
        writeFile = File(url: URL(fileURLWithPath: writePath!))
        writeFile?.writeAsynchFrom(readFile
            , bufferSize: 2048
            , progress: nil
            , completionHandler: { [weak self] (done) in
                if done{
                    print("Secure File Write Successful.")
                    self?.updateDownloadSavePath(forRequest: forRequest, savePath: self?.writeFile?.URL)
                }
                else{
                    print("Secure File Write Failed.")
                }
                let _ = readFile.delete()
        })
    }
    
}
