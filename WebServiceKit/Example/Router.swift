//
//  Router.swift
//  Example
//
//  Created by Towhid Islam on 12/1/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import UIKit
import CoreDataStack

@objc protocol RouterProtocol: UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    func route(from fromVC: UIViewController?, info: NGObject?) -> Void
}

@objc(RouterInfo)
@objcMembers
class RouterInfo: NGObject {
    var storyboard: NSString?
    var toViewController: NSString?
}

@objc(Router)
@objcMembers
class Router: NSObject, RouterProtocol{
    
    private var _next: RouterProtocol?
    private var _existingInfo: NGObject?
    
    var next: RouterProtocol?{
        return _next
    }
    
    override init() {
        super.init()
    }
    
    convenience init(next: RouterProtocol) {
        self.init()
        _next = next
    }
    
    var fromVC: UIViewController?{
        let root = UIApplication.shared.delegate?.window??.rootViewController
        if root is UINavigationController{
            return (root as! UINavigationController).visibleViewController
        }else if root is UITabBarController{
            return (root as! UITabBarController).selectedViewController
        }else if root?.presentingViewController != nil{
            return root?.presentingViewController
        }else{
            return root
        }
    }
    
    func route(from fromVC: UIViewController?, info: NGObject?) -> Void{
        var fromVCon = fromVC
        if fromVCon == nil {
            fromVCon = self.fromVC
        }
        //
        guard let xInfo = info as? RouterInfo else {
            print("RouterInfo is nil, expecting something")
            return
        }
        let board: UIStoryboard?
        if xInfo.storyboard != nil {
            board = UIStoryboard(name: (xInfo.storyboard as String?)!, bundle: nil)
        }else{
            board = fromVCon?.storyboard
        }
        guard let toVCName = xInfo.toViewController else {
            return
        }
        if let toVC = board?.instantiateViewController(withIdentifier: (toVCName as String)){
            fromVCon?.show(toVC, sender: nil)
        }
    }
    
}
