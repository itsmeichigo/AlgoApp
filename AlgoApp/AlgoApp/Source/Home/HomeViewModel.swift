//
//  HomeViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class HomeViewModel {
    
    let questions = BehaviorRelay<[QuestionCellModel]>(value: [])
    var randomQuestionId: Int? {
        return realmManager.objects(Question.self).randomElement()?.id
    }
    
    private let disposeBag = DisposeBag()
    private lazy var realmManager = RealmManager.shared
    
    init() {
        observeCustomLists()
    }
    
    func loadQuestions(query: String?, filter: QuestionFilter?, onlyUnsolved: Bool, sortOption: SortOption) {
        let results = Question.loadQuestions(with: realmManager, query: query, filter: filter, onlyUnsolved: onlyUnsolved)
        
        Observable.collection(from: results)
            .map { Array($0)
                .map { QuestionCellModel(with: $0) }
                .sorted(by: sortOption.sortBlock)
            }
            .bind(to: questions)
            .disposed(by: disposeBag)
    }
    
    private func observeCustomLists() {
        Observable.collection(from: realmManager.objects(QuestionList.self))
            .map { list -> (Set<Int>, Set<Int>)? in
                guard let solvedList = list.first(where: { $0.id == QuestionList.solvedListId }),
                    let savedList = list.first(where: { $0.id == QuestionList.savedListId }) else { return nil }
                
                let solvedIds = Set(solvedList.questionIds
                    .components(separatedBy: ",")
                    .filter { !$0.isEmpty }
                    .map { Int($0) ?? -1 }
                    .filter { $0 != -1 })
                
                let savedIds = Set(savedList.questionIds
                    .components(separatedBy: ",")
                    .filter { !$0.isEmpty }
                    .map { Int($0) ?? -1 }
                    .filter { $0 != -1 })
                
                let solvedQuestionIds = Set(solvedList.questions.map { $0.id })
                let savedQuestionIds = Set(savedList.questions.map { $0.id })
                
                let solvedListChanged = !solvedIds.isSubset(of: solvedQuestionIds) || !solvedQuestionIds.isSubset(of: solvedIds)
                let savedListChanged = !savedIds.isSubset(of: savedQuestionIds) || !savedQuestionIds.isSubset(of: savedIds)
                
                guard solvedListChanged || savedListChanged else { return nil }
                
                return (solvedIds, savedIds)
            }
            .filterNil()
            .distinctUntilChanged { $0.0 != $1.0 && $0.1 != $1.1 }
            .withLatestFrom(questions.asObservable()) { (newList, oldList) -> (Set<Int>, Set<Int>, Set<Int>, Set<Int>) in
                let oldSolvedList = Set(oldList.filter { $0.solved }.map { $0.id })
                let oldSavedList = Set(oldList.filter { $0.saved }.map { $0.id })
                return (newList.0,
                        newList.1,
                        oldSolvedList,
                        oldSavedList)
            }
            .subscribe(onNext: { [weak self] input in
                guard let self = self else { return }
                let (newSolvedList, newSavedList, oldSolvedList, oldSavedList) = input
                
                let indicesToUpdate = newSolvedList.union(newSavedList.union(oldSavedList.union(oldSolvedList)))
                
                guard !indicesToUpdate.isEmpty else { return }
                
                self.realmManager.update {
                    for index in indicesToUpdate {
                        if let model = self.realmManager.object(Question.self, id: index) {
                            model.solved = newSolvedList.contains(index)
                            model.saved = newSavedList.contains(index)
                        }
                    }
                    
                    let solvedList = QuestionList.solvedList
                    solvedList.questions.removeAll()
                    var solvedQuestionList: [Question] = []
                    for id in newSolvedList {
                        if let model = self.realmManager.object( Question.self, id: id) {
                            solvedQuestionList.append(model)
                        }
                    }
                    
                    solvedList.questions.append(objectsIn: solvedQuestionList)
                    
                    let savedList = QuestionList.savedList
                    savedList.questions.removeAll()
                    var savedQuestionList: [Question] = []
                    for id in newSavedList {
                        if let model = self.realmManager.object( Question.self, id: id) {
                            savedQuestionList.append(model)
                        }
                    }
                    
                    savedList.questions.append(objectsIn: savedQuestionList)
                    
                }
            })
            .disposed(by: disposeBag)
    }
}
