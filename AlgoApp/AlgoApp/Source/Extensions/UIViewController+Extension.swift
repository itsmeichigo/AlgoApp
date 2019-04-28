//
//  UIViewController+Extension.swift
//  AlgoApp
//
//  Created by Huong Do on 4/28/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

extension UIViewController {
    var isRegularWidth: Bool {
        return traitCollection.horizontalSizeClass == .regular
    }
    
    var isCompactHeight: Bool {
        return traitCollection.verticalSizeClass == .compact
    }
}
