//
//  XImageView.swift
//  Example
//
//  Created by Towhid Islam on 12/1/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit

class XImageView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        spinner.color = UIColor.red
        spinner.hidesWhenStopped = true
        self.addSubview(spinner)
        self.spinner = spinner
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        spinner.center = self.center
        spinner.startAnimating()
    }
    
    func layoutScrollView() -> Void {
        if self.scrollView != nil{
            self.scrollView.frame = bounds
            self.scrollView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        }
    }
    
    func stopActivity() -> Void {
        spinner.stopAnimating()
    }
    
    func showImage(_ imgx: UIImage?) {
        guard let img = imgx else {
            print("Image is nil")
            return
        }
        
        //SetUp ImageView
        let imageView = ZoomableImageView(image: img)
        self.imageView = imageView
        
        //ImageView and ScrollView canvas retio
        let scrollViewBounds = self.bounds
        let xScale = scrollViewBounds.width / imageView.bounds.width
        let yScale = scrollViewBounds.height / imageView.bounds.height
        let minScale = min(xScale, yScale)
        
        //Setup ScrollView
        let scrollView = UIScrollView(frame: scrollViewBounds)
        self.scrollView = scrollView
        scrollView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        scrollView.clipsToBounds = false
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.gray
        
        //add imageView to scrollView
        scrollView.addSubview(imageView)
        
        //Setting ZoomScale
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 10
        scrollView.zoomScale = minScale
        
        //Setting ContentSize
        scrollView.contentSize = scrollView.bounds.size
        
        //Following line will forward pinch gesture on View to ScrollView
        self.addGestureRecognizer(scrollView.pinchGestureRecognizer!)
        self.addGestureRecognizer(scrollView.panGestureRecognizer)
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

extension XImageView : UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
