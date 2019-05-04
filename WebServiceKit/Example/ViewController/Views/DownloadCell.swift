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
    
    static let backgroundColor = "A7E9FF"
    
    weak var downloader: DownloadQueue!
    @IBOutlet weak var pathLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    var model: DownloadModel!
    var tapLocation: CGPoint = CGPoint()
    
    override func awakeFromNib() {
        progressBar.progress = 0
        contentView.backgroundColor = UIColor.hex(DownloadCell.backgroundColor, alpha: 0.6)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tapLocation = contentView.center
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event){
            if view.bounds.contains(point){
                tapLocation = point
            }
            return view
        }
        return nil
    }
    
    func updateDisplay(model: DownloadModel){
        //
        self.model = model
        pathLabel.text = (model.request?.baseUrl as NSString!).lastPathComponent
        if model.savedUrl == nil{
            progressBar.progress = 0.0
            if model.progress == nil{
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
            NTLocalNotificationCenter.stepDownBadgeNumber(forType: "DownloadAction", message: "Download Cancel")
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
