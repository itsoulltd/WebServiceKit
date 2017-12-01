//
//  ImageViewerController.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 3/25/15.
//  Copyright (c) 2015 Towhid (Selise.ch). All rights reserved.
//

import UIKit
import CoreNetworkStack
import CoreDataStack
import WebServiceKit
import FileSystemSDK

@objc(XImageViewerController)
class XImageViewerController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var model: DownloadModel?
    
    var selfView: XImageView {
        return self.view as! XImageView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //So that image don't overlap when hit back button
        view.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadFile()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        selfView.layoutScrollView()
    }
    
    fileprivate var readFile: File? = nil
    fileprivate func loadFile(){
        if let url = model?.savedUrl{
            let fileName = url.lastPathComponent
            let imagesFolder = Folder(name: "Images", searchDirectoryType: FileManager.SearchPathDirectory.cachesDirectory)
            let readPath = imagesFolder.path()?.appendingPathComponent(fileName)
            readFile = File(url: URL(fileURLWithPath: readPath!))
            readFile?.decrypted(bufferSize: 2048, progress: nil, decrypt: { (data) -> Data in
                return data
            }, completionHandler: { [weak self] (raw: Data) in
                if raw.count > 0{
                    DispatchQueue.main.async {
                        self?.selfView.stopActivity()
                        self?.selfView.showImage(UIImage(data: raw))
                    }
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
