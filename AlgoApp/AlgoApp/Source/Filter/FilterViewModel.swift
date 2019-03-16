//
//  FilterViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/20/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import RxRealm

final class FilterViewModel {
    let allTags = BehaviorRelay<[String]>(value: [])
    let allCompanies = BehaviorRelay<[String]>(value: [])
    let currentFilterRelay = BehaviorRelay<QuestionFilter?>(value: nil)
    
    private var selectedCategories: [String] = []
    private var selectedCompanies: [String] = []
    private var selectedLevels: [String] = []
    private var selectedRemarks: [String] = []
    
    private let disposeBag = DisposeBag()
    private let realm = try! Realm()
    
    init() {
        loadTags()
        loadCompanies()
    }
    
    func updateCategory(_ category: String) {
        if let index = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
        
        updateCurrentFilter()
    }
    
    func updateCompany(_ company: String) {
        if let index = selectedCategories.firstIndex(of: company) {
            selectedCompanies.remove(at: index)
        } else {
            selectedCompanies.append(company)
        }
        
        updateCurrentFilter()
    }
    
    func updateLevel(_ level: String) {
        if let index = selectedLevels.firstIndex(of: level) {
            selectedLevels.remove(at: index)
        } else {
            selectedLevels.append(level)
        }
        
        updateCurrentFilter()
    }
    
    func updateRemark(_ remark: String) {
        if let index = selectedRemarks.firstIndex(of: remark) {
            selectedRemarks.remove(at: index)
        } else {
            selectedRemarks.append(remark)
        }
        
        updateCurrentFilter()
    }
    
    func buildFilter(shouldClearAll: Bool) -> QuestionFilter {
        guard !shouldClearAll else {
            return QuestionFilter(tags: [], companies: [], levels: [], topLiked: false, topInterviewed: false)
        }
        
        var levels: [Question.DifficultyLevel] = []
        for level in Question.DifficultyLevel.allCases {
            if selectedLevels.contains(level.title) {
                levels.append(level)
            }
        }
        
        let topLiked = selectedRemarks.contains(Question.Remarks.topLiked.title)
        let topInterviewed = selectedRemarks.contains(Question.Remarks.topInterviewed.title)
        
        return QuestionFilter(tags: selectedCategories, companies: selectedCompanies, levels: levels, topLiked: topLiked, topInterviewed: topInterviewed)
    }
    
    private func updateCurrentFilter() {
        currentFilterRelay.accept(buildFilter(shouldClearAll: false))
    }
    
    private func loadTags() {
        Observable.collection(from: realm.objects(Tag.self))
            .map { $0.map { $0.name } }
            .bind(to: allTags)
            .disposed(by: disposeBag)
    }
    
    private func loadCompanies() {
        Observable.collection(from: realm.objects(Company.self))
            .map { $0.map { $0.name } }
            .bind(to: allCompanies)
            .disposed(by: disposeBag)
    }
}
