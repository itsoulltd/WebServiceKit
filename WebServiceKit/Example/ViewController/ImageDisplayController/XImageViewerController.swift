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
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var model: DownloadCellModel?
    var spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        spinner.color = UIColor.red
        spinner.center = self.view.center
        view.addSubview(spinner)
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
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
                        self?.spinner.stopAnimating()
                        self?.showImage(UIImage(data: raw))
                    }
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func showImage(_ imgx: UIImage?) {
        guard let img = imgx else {
            print("Image is nil")
            return
        }
        let imgSize = img.size
        
        //ImageView and ScrollView canvas retio
        let maxcanvasSize = CGSize(width: (0.9 * view.bounds.size.width), height: ((0.7 * view.bounds.size.height) - 64.0))
        let xScale = imgSize.width / maxcanvasSize.width
        let yScale = imgSize.height / maxcanvasSize.height
        let scale = max(xScale, yScale)
        let scrollViewBounds = CGRect(x: 0, y: 0, width: (imgSize.width / scale), height: (imgSize.height / scale))
        let centerX = view.bounds.size.width / 2
        let centerY = (maxcanvasSize.height / 2) + 64.0
        
        //Setup ScrollView
        let scrollView = UIScrollView(frame: scrollViewBounds)
        self.scrollView = scrollView
        scrollView.center = CGPoint(x: centerX, y: centerY)
        scrollView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scrollView.clipsToBounds = false
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.red //Change to other color to see the bounds of scrollView
        
        //SetUp ImageView
        let imageView = TapableImageView(image: img)
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)
        self.imageView = imageView
        
        //Setting ZoomScale
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 10
        scrollView.zoomScale = 1
        
        //Setting ContentSize
        scrollView.contentSize = imageView.bounds.size //Or scrollView's self bounds
        
        //Following line will forward pinch gesture on View to ScrollView
        view.addGestureRecognizer(scrollView.pinchGestureRecognizer!)
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        //
        imageView.singleTap = {(location: CGPoint) -> Void in
            print(location)
            let zoomScale = scrollView.zoomScale * 0.2
            //scrollView.setZoomScale(zoomScale, animated: true)
            let rectToZoom = self.zoomingRect(scale: zoomScale, center: location)
            scrollView.zoom(to: rectToZoom, animated: true)
        }
        
        imageView.doubleTap = {(location: CGPoint) -> Void in
            print(location)
            let zoomScale = scrollView.zoomScale / 0.2
            //scrollView.setZoomScale(zoomScale, animated: true)
            let rectToZoom = self.zoomingRect(scale: zoomScale, center: location)
            scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    fileprivate func zoomingRect(scale: CGFloat, center: CGPoint) -> CGRect{
        var rect = CGRect()
        rect.size.width = scrollView.bounds.width / scale
        rect.size.height = scrollView.bounds.height / scale
        rect.origin.x = center.x - (rect.width / 2)
        rect.origin.y = center.y - (rect.height / 2)
        return rect
    }

}

extension XImageViewerController : UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
