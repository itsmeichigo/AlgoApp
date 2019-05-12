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

enum SortOption: Int, CaseIterable {
    case oldestFirst
    case newestFirst
    case easyFirst
    case hardFirst
    case random
    
    var displayText: String {
        switch self {
        case .oldestFirst: return "Old to new"
        case .newestFirst: return "New to old"
        case .easyFirst: return "Easy to hard"
        case .hardFirst: return "Hard to easy"
        case .random: return "Randomly"
        }
    }
    
    var sortBlock: ((QuestionCellModel, QuestionCellModel) -> Bool) {
        switch self {
        case .oldestFirst:
            return { $0.id < $1.id }
        case .newestFirst:
            return { $0.id > $1.id }
        case .easyFirst:
            return { $0.rawDifficultyLevel < $1.rawDifficultyLevel }
        case .hardFirst:
            return { $0.rawDifficultyLevel > $1.rawDifficultyLevel }
        case .random:
            return { _, _ in Bool.random() }
        }
    }
}

final class AppConfigs {
    static let shared = AppConfigs()
    
    var hidesSolvedProblemsDriver: Driver<Bool> {
        return hidesSolvedProblemsRelay.asDriver()
    }
    
    var isPremiumDriver: Driver<Bool> {
        return isPremiumRelay.asDriver()
    }
    
    var sortOptionDriver: Driver<SortOption> {
        return sortOptionRelay.asDriver()
    }
    
    var currentFilterDriver: Driver<QuestionFilter> {
        return currentFilterRelay.asDriver()
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
    
    var sortOption: SortOption {
        get {
            let optionValue = UserDefaults.standard.integer(forKey: sortOptionKey)
            let option = SortOption(rawValue: optionValue) ?? .oldestFirst
            if option != sortOptionRelay.value {
                sortOptionRelay.accept(option)
            }
            
            return option
        }
        
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: sortOptionKey)
            sortOptionRelay.accept(newValue)
        }
    }
    
    var currentFilter: QuestionFilter {
        get {
            guard let filterData = UserDefaults.standard.object(forKey: currentFilterKey) as? Data else {
                return QuestionFilter.emptyFilter
            }
            let filter = try? JSONDecoder().decode(QuestionFilter.self, from: filterData)
            return filter ?? QuestionFilter.emptyFilter
        }
        
        set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: currentFilterKey)
                currentFilterRelay.accept(newValue)
            } catch {
//                print("error: \(error)")
            }
        }
    }
    
    private let hidesSolvedProblemsKey = "HidesSolvedProblems"
    private let hidesSolvedProblemsRelay = BehaviorRelay<Bool>(value: false)
    
    private let isPremiumKey = "IsPremium"
    private let isPremiumRelay = BehaviorRelay<Bool>(value: false)
    
    private let sortOptionKey = "SortOptionKey"
    private let sortOptionRelay = BehaviorRelay<SortOption>(value: .oldestFirst)
    
    private let currentFilterKey = "CurrentFilterKey"
    private let currentFilterRelay = BehaviorRelay<QuestionFilter>(value: QuestionFilter.emptyFilter)
}
