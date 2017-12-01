//
//  DownloadCell.swift
//  Example
//
//  Created by Towhid Islam on 11/24/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import UIKit
import CoreDataStack
import WebServiceKit
import CoreNetworkStack

class DownloadModel: NGObject {
    
    @objc public var request: HttpWebRequest?
    @objc public var progress: Progress?
    @objc public var savedUrl: URL?
}

class DownloadCell: UITableViewCell {
    
    weak var downloader: DownloadQueue!
    @IBOutlet weak var pathLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    var model: DownloadModel!
    
    override func awakeFromNib() {
        //
    }
    
    func updateDisplay(model: DownloadModel){
        //
        self.model = model
        pathLabel.text = (model.request?.baseUrl as NSString!).lastPathComponent
        if model.savedUrl == nil{
            if model.progress == nil{
                progressBar.progress = 0.0
                let prog = Progress()
                model.progress = prog
                model.progress?.progressBar = progressBar
                downloader.enqueueRequest(model.request!, progressListener: model.progress)
            }
            else{
                model.progress?.progressBar = progressBar
            }
        }
        else{
            progressBar.progress = 1.0
        }
    }//
    
    @IBAction func cancelAction(sender: UIButton?){
        //
        if let model = self.model{
            downloader.cancelRequest(model.request!)
            LocalNotificationCenter.stepDownBadgeNumber(forType: "DownloadAction", message: "Download Cancel")
        }
    }
}

class Progress: NSObject, ProgressListener {
    
    weak var progressBar: UIProgressView!
    
    func progressStart() {
        //
    }
    
    func progressUpdate(_ percentage: CGFloat) {
        //
        if progressBar != nil{
            progressBar.progress = Float(percentage)
        }
    }
    
    func progressEnd() {
        //
        if progressBar != nil{
            progressBar.progress = 1.0
        }
    }
}
