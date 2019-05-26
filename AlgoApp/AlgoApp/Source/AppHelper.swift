//
//  AppHelper.swift
//  AlgoApp
//
//  Created by Huong Do on 4/21/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

enum AppHelper {
    
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var homeStoryboard: UIStoryboard {
        return UIStoryboard(name: "Home", bundle: nil)
    }
    
    static var remindersStoryboard: UIStoryboard {
        return UIStoryboard(name: "Reminders", bundle: nil)
    }
    
    static var notesStoryboard: UIStoryboard {
        return UIStoryboard(name: "Notes", bundle: nil)
    }
    
    static var settingsStoryboard: UIStoryboard {
        return UIStoryboard(name: "Settings", bundle: nil)
    }
    
    static func showQuestionDetail(for questionId: Int, failureHandler: (() -> Void)? = nil) {
        
        guard let window = UIApplication.shared.keyWindow,
            let tabbarController = window.rootViewController as? UITabBarController,
            let splitViewController = tabbarController.viewControllers?.first as? UISplitViewController else {
                failureHandler?()
                return
        }
        
        if let presentedController = splitViewController.presentedViewController {
            presentedController.dismiss(animated: false, completion: nil)
        }
        
        guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else { return }
        
        if let homeViewController = navigationController.topViewController as? HomeViewController {
            homeViewController.updateDetailController(with: questionId)
        } else if let detailNavigationController = navigationController.topViewController as? UINavigationController {
            detailNavigationController.popToRootViewController(animated: false)
            
            if let detailController = detailNavigationController.topViewController as? DetailViewController {
                detailController.viewModel.updateDetails(with: questionId)
            }
        }
        
        tabbarController.selectedIndex = 0
    }
}
