//
//  NavigationController.swift
//  PanModal
//
//  Created by Stephen Sowole on 2/26/19.
//  Copyright © 2019 PanModal. All rights reserved.
//

import UIKit
import PanModal

class PannableNavigationController: UINavigationController, PanModalPresentable {

    // MARK: - Pan Modal Presentable

    var panScrollable: UIScrollView? {
        return (topViewController as? PanModalPresentable)?.panScrollable
    }

    var shortFormHeight: PanModalHeight {
        let height = UIScreen.main.bounds.size.height * 2 / 3
        return .contentHeight(height)
    }
}

