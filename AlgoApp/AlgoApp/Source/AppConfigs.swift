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

enum Theme: Int {
    case light
    case dark
}

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
    
    var isPremiumDriver: Driver<Bool> {
        return isPremiumRelay.asDriver()
    }
    
    var sortOptionDriver: Driver<SortOption> {
        return sortOptionRelay.asDriver()
    }
    
    var currentFilterDriver: Driver<QuestionFilter> {
        return currentFilterRelay.asDriver()
    }
    
    var isPremium: Bool {
        get {
            let premium = UserDefaults.standard.bool(forKey: AppConfigs.isPremiumKey)
            if premium != isPremiumRelay.value {
                isPremiumRelay.accept(premium)
            }
            
            return premium
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: AppConfigs.isPremiumKey)
            isPremiumRelay.accept(newValue)
        }
    }
    
    var sortOption: SortOption {
        get {
            let optionValue = UserDefaults.standard.integer(forKey: AppConfigs.sortOptionKey)
            let option = SortOption(rawValue: optionValue) ?? .oldestFirst
            if option != sortOptionRelay.value {
                sortOptionRelay.accept(option)
            }
            
            return option
        }
        
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: AppConfigs.sortOptionKey)
            sortOptionRelay.accept(newValue)
        }
    }
    
    var currentFilter: QuestionFilter {
        get {
            guard let filterData = UserDefaults.standard.object(forKey: AppConfigs.currentFilterKey) as? Data else {
                return QuestionFilter.emptyFilter
            }
            let filter = try? JSONDecoder().decode(QuestionFilter.self, from: filterData)
            return filter ?? QuestionFilter.emptyFilter
        }
        
        set {
            do {
                let encoded = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(encoded, forKey: AppConfigs.currentFilterKey)
                currentFilterRelay.accept(newValue)
            } catch {}
        }
    }
    
    var currentThemeDriver: Driver<Theme> {
        return currentThemeRelay.asDriver()
    }
    
    var currentTheme: Theme {
        get {
            let themeValue = UserDefaults.standard.integer(forKey: AppConfigs.themeKey)
            let theme = Theme(rawValue: themeValue) ?? .light
            if theme != currentThemeRelay.value {
                currentThemeRelay.accept(theme)
            }
            return theme
        }
        
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: AppConfigs.themeKey)
            currentThemeRelay.accept(newValue)
        }
    }
    
    static let isPremiumKey = "IsPremium"
    private let isPremiumRelay = BehaviorRelay<Bool>(value: false)
    
    static let sortOptionKey = "SortOptionKey"
    private let sortOptionRelay = BehaviorRelay<SortOption>(value: .oldestFirst)
    
    static let currentFilterKey = "CurrentFilterKey"
    private let currentFilterRelay = BehaviorRelay<QuestionFilter>(value: QuestionFilter.emptyFilter)
    
    static let themeKey = "SavedTheme"
    private let currentThemeRelay = BehaviorRelay<Theme>(value: .light)
    
    private let disposeBag = DisposeBag()
    
    func registerInitialValues() {
        var values: [String: Any] = [
            AppConfigs.isPremiumKey: isPremium,
            AppConfigs.sortOptionKey: sortOption.rawValue,
            AppConfigs.themeKey: currentTheme.rawValue
        ]
        
        if let filterData = UserDefaults.standard.object(forKey: AppConfigs.currentFilterKey) as? Data {
            values[AppConfigs.currentFilterKey] = filterData
        }
        
        UserDefaults.standard.register(defaults: values)
    }
    
    func observeUserDefaultsChange() {
        
        UserDefaults.standard.rx
            .observe(Bool.self, AppConfigs.isPremiumKey)
            .filterNil()
            .bind(to: isPremiumRelay)
            .disposed(by: disposeBag)
        
        UserDefaults.standard.rx
            .observe(Int.self, AppConfigs.sortOptionKey)
            .filterNil()
            .map { SortOption(rawValue: $0) }
            .filterNil()
            .bind(to: sortOptionRelay)
            .disposed(by: disposeBag)
        
        UserDefaults.standard.rx
            .observe(Int.self, AppConfigs.themeKey)
            .filterNil()
            .map { Theme(rawValue: $0) }
            .filterNil()
            .bind(to: currentThemeRelay)
            .disposed(by: disposeBag)
        
        UserDefaults.standard.rx
            .observe(Data.self, AppConfigs.currentFilterKey)
            .filterNil()
            .map { filterData in
                let filter = try? JSONDecoder().decode(QuestionFilter.self, from: filterData)
                return filter ?? QuestionFilter.emptyFilter
            }
            .bind(to: currentFilterRelay)
            .disposed(by: disposeBag)
    }
}

