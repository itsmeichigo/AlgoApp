//
//  AppConfigs.swift
//  AlgoApp
//
//  Created by Huong Do on 3/16/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class AppConfigs {
    static let shared = AppConfigs()
    
    var hidesSolvedProblemsDriver: Driver<Bool> {
        return hidesSolvedProblemsRelay.asDriver()
    }
    
    var isPremiumDriver: Driver<Bool> {
        return isPremiumRelay.asDriver()
    }
    
    var hidesSolvedProblems: Bool {
        get {
            let hiding = UserDefaults.standard.bool(forKey: hidesSolvedProblemsKey)
            if hiding != hidesSolvedProblemsRelay.value {
                hidesSolvedProblemsRelay.accept(hiding)
            }
            return hiding
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: hidesSolvedProblemsKey)
            hidesSolvedProblemsRelay.accept(newValue)
        }
    }
    
    var isPremium: Bool {
        get {
            let premium = UserDefaults.standard.bool(forKey: isPremiumKey)
            if premium != isPremiumRelay.value {
                isPremiumRelay.accept(premium)
            }
            
            return premium
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: isPremiumKey)
            isPremiumRelay.accept(newValue)
        }
    }
    
    private let hidesSolvedProblemsKey = "HidesSolvedProblems"
    private let hidesSolvedProblemsRelay = BehaviorRelay<Bool>(value: false)
    
    private let isPremiumKey = "IsPremium"
    private let isPremiumRelay = BehaviorRelay<Bool>(value: false)
    
}
