//
//  TapableImageView.swift
//  Example
//
//  Created by Towhid Islam on 11/25/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import UIKit

class TapableImageView: UIImageView {
    
    var singleTap: ((_ location: CGPoint) -> Void)?
    var doubleTap: ((_ location: CGPoint) -> Void)?
    
    override init(image: UIImage?) {
        super.init(image: image)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup(){
        isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(TapableImageView.singleTapAction(sender:)))
        singleTap.numberOfTapsRequired = 1
        addGestureRecognizer(singleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(TapableImageView.doubleTapAction(sender:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        //Single Tap detection will delayed by double tap detection. 
        singleTap.require(toFail: doubleTap)
    }
    
    @objc func singleTapAction(sender: UIGestureRecognizer) -> Void {
        //
        let point = sender.location(in: self)
        if let tap = singleTap{
            tap(point)
        }
    }
    
    @objc func doubleTapAction(sender: UIGestureRecognizer) -> Void {
        //
        let point = sender.location(in: self)
        if let tap = doubleTap{
            tap(point)
        }
    }
    
}
