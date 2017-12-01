//
//  ImageViewRouter.swift
//  Example
//
//  Created by Towhid Islam on 12/1/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit
import CoreDataStack

class XImageViewRouter: Router {
    
    override func route(from fromVC: UIViewController?, info: NGObject?) {
        var fromViewCon = fromVC
        if fromViewCon == nil {
            fromViewCon = self.fromVC
        }
        let viewController = fromViewCon?.storyboard?.instantiateViewController(withIdentifier: "XImageViewerController") as! XImageViewerController
             viewController.model = info as? DownloadModel
             if #available(iOS 8.0, *) {
                fromViewCon?.show(viewController, sender: nil)
             } else {
                if let nav = fromViewCon?.navigationController{
                    nav.pushViewController(viewController, animated: true)
                }else{
                    fromViewCon?.modalPresentationStyle = UIModalPresentationStyle.currentContext
                    fromViewCon?.present(viewController, animated: true, completion: nil)
                }
         }
        //
    }

}
