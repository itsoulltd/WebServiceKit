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

class ImageViewerController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var baseUrl = "http://localhost:8080/MediaService/"
    //"http://192.168.210.115:8080/MediaService"//
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    var model: DownloadCellModel?
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if progressBar != nil{
            progressBar.progress = 0.0
        }
        spinner.color = UIColor.red
        spinner.center = self.view.center
        self.view.insertSubview(spinner, aboveSubview: imageView)
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadFile()
    }
    
    fileprivate var readFile: File? = nil
    fileprivate func loadFile(){
        if let url = model?.savedUrl{
            let fileName = url.lastPathComponent!
            let imagesFolder = Folder(name: "Images", searchDirectoryType: FileManager.SearchPathDirectory.cachesDirectory)
            let readPath = imagesFolder.path()?.appendingPathComponent(fileName)
            readFile = File(url: URL(fileURLWithPath: readPath!))
            readFile?.decrypted(bufferSize: 2048, progress: nil, decrypt: { (data) -> Data in
                return data
            }, completionHandler: { [weak self] (raw: Data) in
                if raw.count > 0{
                    DispatchQueue.main.async {
                        self?.spinner.stopAnimating()
                        self?.imageView.image = UIImage(data: raw)
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
