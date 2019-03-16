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
    
    var showsReadProblemDriver: Driver<Bool> {
        return showsReadProblemRelay.asDriver()
    }
    
    var showsReadProblem: Bool {
        get {
            let showing = UserDefaults.standard.bool(forKey: showsReadProblemsKey)
            showsReadProblemRelay.accept(showing)
            return showing
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: showsReadProblemsKey)
            showsReadProblemRelay.accept(newValue)
        }
    }
    
    private let showsReadProblemsKey = "ShowsReadProblems"
    private let showsReadProblemRelay = BehaviorRelay<Bool>(value: true)
    
}
