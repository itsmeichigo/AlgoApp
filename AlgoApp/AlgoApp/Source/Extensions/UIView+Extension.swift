//
//  UIView+Extension.swift
//  AlgoApp
//
//  Created by Huong Do on 3/16/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

extension UIView {
    func dropCardShadow() {
        let color = AppConfigs.shared.currentTheme == .light ? UIColor(rgb: 0x333333) : UIColor.black
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 3.0
    }
}
