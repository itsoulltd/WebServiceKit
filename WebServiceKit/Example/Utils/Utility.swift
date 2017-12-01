//
//  Utility.swift
//  Example
//
//  Created by Towhid Islam on 11/18/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func hex(_ value: String, alpha: CGFloat = 1.0) -> UIColor{
        if value.count <= 0 {
            return UIColor.gray
        }
        //
        var rgb: UInt32 = 0
        let scanner = Scanner(string: value)
        if value.count > 6 {
            // bypass '#' character
            scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        }
        scanner.scanHexInt32(&rgb)
        //
        let color = UIColor(red: CGFloat((rgb & 0xff0000) >> 16) / 255.0
            , green: CGFloat((rgb & 0xff00) >> 8) / 255.0
            , blue: CGFloat((rgb & 0xff) >> 0) / 255.0
            , alpha: alpha)
        return color
    }
    
}
