//
//  UINavigationBar+Extension.swift
//  VinID
//
//  Created by Huong Do on 11/30/18.
//  Copyright © 2018 vinid. All rights reserved.
//

import UIKit

extension UINavigationController {
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
