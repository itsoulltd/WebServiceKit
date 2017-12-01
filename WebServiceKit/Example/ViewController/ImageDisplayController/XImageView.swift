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
        layoutSubviewsAfterOrientationChanges()
    }
    
    fileprivate func layoutSubviewsAfterOrientationChanges() -> Void {
        if self.scrollView != nil{
            self.scrollView.frame = bounds
            setZoomProperty(scrollViewSize: self.scrollView.bounds.size)
            self.scrollView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            if scrollView.zoomScale < scrollView.minimumZoomScale{
                scrollView.zoomScale = scrollView.minimumZoomScale
            }
            recenterImageViewContent()
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
        
        //Setup ScrollView
        let scrollViewBounds = self.bounds
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
        
        //Setting ZoomScale
        setZoomProperty(scrollViewSize: scrollViewBounds.size)
        
        //Setting ContentSize
        scrollView.contentSize = scrollView.bounds.size
        
        //add imageView to scrollView
        scrollView.addSubview(imageView)
        //ImageView Recenter
        recenterImageViewContent()
        
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
    
    fileprivate func setZoomProperty(scrollViewSize: CGSize){
        
        let imageSize = self.imageView.bounds.size
        let xScale = scrollViewSize.width / imageSize.width
        let yScale = scrollViewSize.height / imageSize.height
        let minScale = min(xScale, yScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 10
        scrollView.zoomScale = minScale
    }
    
    fileprivate func zoomingRect(scale: CGFloat, center: CGPoint) -> CGRect{
        var rect = CGRect()
        rect.size.width = scrollView.bounds.width / scale
        rect.size.height = scrollView.bounds.height / scale
        rect.origin.x = center.x - (rect.width / 2)
        rect.origin.y = center.y - (rect.height / 2)
        return rect
    }
    
    fileprivate func recenterImageViewContent() {
        
        let scrollViewBounds = self.scrollView.bounds
        let imageFrame = self.imageView.frame

        let horizontalSpace = imageFrame.size.width < scrollViewBounds.size.width ? ((scrollViewBounds.size.width - imageFrame.size.width) / 2) : 0
        let verticalSpace = imageFrame.size.height < scrollViewBounds.size.height ? ((scrollViewBounds.size.height - imageFrame.size.height) / 2) : 0

        self.scrollView.contentInset = UIEdgeInsets(top: verticalSpace, left: horizontalSpace, bottom: verticalSpace, right: horizontalSpace)
        
    }

}

extension XImageView : UIScrollViewDelegate{
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //recenterImageViewContent()
    }
}
