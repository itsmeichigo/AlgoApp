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
}
