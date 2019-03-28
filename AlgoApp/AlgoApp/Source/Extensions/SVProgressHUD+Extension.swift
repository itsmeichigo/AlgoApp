//
//  SVProgressHUD+Extension.swift
//  AlgoApp
//
//  Created by Huong Do on 3/28/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import SVProgressHUD

extension SVProgressHUD {
    public static func configure() {
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setDefaultAnimationType(.flat)
        
        SVProgressHUD.setCornerRadius(4.0)
        SVProgressHUD.setRingNoTextRadius(24)
        SVProgressHUD.setMinimumDismissTimeInterval(5.0)
        SVProgressHUD.setForegroundColor(UIColor(white: 1, alpha: 1))
        SVProgressHUD.setBackgroundColor(UIColor(white: 0.0, alpha: 0.7))
        
        SVProgressHUD.setFadeOutAnimationDuration(0.30)
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: 16))
        SVProgressHUD.setMinimumSize(CGSize(width: 96, height: 96))
        SVProgressHUD.setGraceTimeInterval(0.0)
        SVProgressHUD.setMaxSupportedWindowLevel(.statusBar)
    }
}
