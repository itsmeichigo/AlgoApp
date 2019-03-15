//
//  UIColor+Utility.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIColor {
    static func primaryColor() -> UIColor {
        switch Themer.shared.currentTheme {
        case .light: return .white
        case .dark: return UIColor(rgb: 0x333333)
        }
    }
    
    static func secondaryOrangeColor() -> UIColor {
        return UIColor(rgb: 0xFB866C)
    }
    
    static func secondaryYellowColor() -> UIColor {
        switch Themer.shared.currentTheme {
        case .light: return UIColor(rgb: 0xFF945A)
        case .dark: return UIColor(rgb: 0xFFD452)
        }
    }
    
    static func secondaryBlueColor() -> UIColor {
        return UIColor(rgb: 0x618ED9)
    }
    
    static func secondaryGreenColor() -> UIColor {
        return UIColor(rgb: 0x66BD90)
    }
    
    static func secondaryRedColor() -> UIColor {
        return UIColor(rgb: 0xED6B68)
    }
    
    static func secondaryPurpleColor() -> UIColor {
        return UIColor(rgb: 0x8774D8)
    }

    static func borderColor() -> UIColor {
        switch Themer.shared.currentTheme {
        case .light: return UIColor(rgb: 0xc3c3c3)
        case .dark: return UIColor(rgb: 0xc3c3c3).withAlphaComponent(0.4)
        }
    }
    
    static func subtitleTextColor() -> UIColor {
        return UIColor(rgb: 0x999999)
    }
    
    static func titleTextColor() -> UIColor {
        switch Themer.shared.currentTheme {
        case .light: return UIColor(rgb: 0x333333)
        case .dark: return .white
        }
    }
    
    static func backgroundColor() -> UIColor {
        switch Themer.shared.currentTheme {
        case .light: return UIColor(rgb: 0xf4f4f4)
        case .dark: return UIColor(rgb: 0x424242)
        }
    }
}
