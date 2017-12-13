//
//  ViewController.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 3/16/15.
//  Copyright (c) 2015 Towhid (Selise.ch). All rights reserved.
//

import UIKit
import CoreNetworkStack
import CoreDataStack
import WebServiceKit
import FileSystemSDK

class RootViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var linkInputField: UITextField!
    @IBOutlet weak var downloadPresenter: DownloadPresenter!
    
    var vcdownloader: DownloadQueue = {
        var config = RequestQueueConfiguration(identifier: "viewDownloadSynch", info: [RequestQueueConfiguration.Keys.MaxTryCount:2])
        var instance = DownloadQueue(configuration: config)
        instance.restoreState()
        return instance
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Configure tableView
        downloadPresenter.configure(downloader: vcdownloader, router: XImageViewRouter())
        //Load UrlList
        loadUrlList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vcdownloader.activateInternetReachability()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vcdownloader.deactivateInternetReachability()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    
    fileprivate var URList: [String] = [String]()
    
    fileprivate func loadUrlList(){
        if let urlListPath = Bundle.main.url(forResource: "wallpaper", withExtension: "plist"){
            if let urls = NSArray(contentsOf: urlListPath){
                for item in urls as! [String]{
                    URList.append(item)
                }
            }
        }
    }
    
    private func getRandomUrl() -> String?{
        if URList.count < 0{
            return nil
        }
        //pick a random number based on [0 =< x < URList.count]
        let seed = UInt32(URList.count - 1)
        let x = Int(arc4random_uniform(seed))
        let pickedData = URList[x]
        return pickedData
    }
    
    @IBAction func downloadAction(sender: UIButton) {
        //
        var finalUrl: String?
        if let hitUrl = linkInputField.text as NSString?{
            if (hitUrl.hasPrefix("http://") || hitUrl.hasPrefix("https://")){
                finalUrl = hitUrl as String
            }
            else{
                finalUrl = "http://\(hitUrl)"
            }
        }
        LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
        let downloadCap = HttpWebRequest(baseUrl: finalUrl)
        //Its a bug, otherwise crash when reload Queue from filesystem.
        downloadCap?.payLoad = NGObject()
        downloadPresenter.insertModel(forRequest: downloadCap, progress: nil)
    }
    
    @IBAction func proactiveAction(sender: UIButton) {
        //
        if let url = getRandomUrl(){
            LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
            let downloadCap = HttpWebRequest(baseUrl: url)
            //Its a bug, otherwise crash when reload Queue from filesystem.
            downloadCap?.payLoad = NGObject()
            vcdownloader.enqueueRequest(downloadCap!)
        }
    }
    
    @IBAction func reactiveAction(sender: UIButton) {
        //
        if let url = getRandomUrl(){
            LocalNotificationCenter.stepUpBadgeNumber(forType: "DownloadAction")
            let downloadCap = HttpWebRequest(baseUrl: url)
            //Its a bug, otherwise crash when reload Queue from filesystem.
            downloadCap?.payLoad = NGObject()
            downloadPresenter.insertModel(forRequest: downloadCap, progress: nil)
        }
    }
    
}

