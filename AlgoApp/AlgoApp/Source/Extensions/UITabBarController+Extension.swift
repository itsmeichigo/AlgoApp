//
//  UITabBarController+Extension.swift
//  VinID
//
//  Created by Huong Do on 11/30/18.
//  Copyright © 2018 vinid. All rights reserved.
//

import UIKit

extension UITabBarController {
    open override var childForStatusBarStyle: UIViewController? {
        return selectedViewController
    }
}

extension UISplitViewController {
    open override var childForStatusBarStyle: UIViewController? {
        return viewControllers.first
    }
}
