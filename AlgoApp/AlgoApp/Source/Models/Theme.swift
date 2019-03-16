//
//  Theme.swift
//  AlgoApp
//
//  Created by Huong Do on 2/18/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa

enum Theme: Int {
    case light
    case dark
}

final class Themer {
    static let shared = Themer()
    
    private let themeKey = "SavedTheme"
    private let currentThemeRelay = BehaviorRelay<Theme>(value: .light)
    
    var currentThemeDriver: Driver<Theme> {
        return currentThemeRelay.asDriver()
    }
    
    var currentTheme: Theme {
        get {
            let theme = UserDefaults.standard.integer(forKey: themeKey)
            return Theme(rawValue: theme) ?? .light
        }
        
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            currentThemeRelay.accept(newValue)
        }
    }
}
