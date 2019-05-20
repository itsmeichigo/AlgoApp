//
//  HomeViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import RxCocoa
import RxRealm
import RxSwift

final class HomeViewModel {
    
    let questions = BehaviorRelay<[QuestionCellModel]>(value: [])
    var randomQuestionId: Int? {
        return realm.objects(Question.self).randomElement()?.id
    }
    
    private let disposeBag = DisposeBag()
    private lazy var realm = try! Realm()
    
    init() {
        observeCustomLists()
    }
    
    func loadQuestions(query: String?, filter: QuestionFilter?, onlyUnsolved: Bool, sortOption: SortOption) {
        let results = Question.loadQuestions(with: realm, query: query, filter: filter, onlyUnsolved: onlyUnsolved)
        
        Observable.collection(from: results)
            .map { Array($0)
                .map { QuestionCellModel(with: $0) }
                .sorted(by: sortOption.sortBlock)
            }
            .bind(to: questions)
            .disposed(by: disposeBag)
    }
    
    private func observeCustomLists() {
        Observable.collection(from: realm.objects(QuestionList.self))
            .map { [weak self] list -> ([Int], [Int])? in
                guard let solvedList = list.first(where: { $0.id == QuestionList.solvedListId }),
                    let savedList = list.first(where: { $0.id == QuestionList.savedListId }) else { return nil }
                
                let solvedIds = solvedList.questionIds.components(separatedBy: ",").filter { !$0.isEmpty }
                let savedIds = savedList.questionIds.components(separatedBy: ",").filter { !$0.isEmpty }
                
                guard solvedIds.count != solvedList.questions.count &&
                    savedIds.count != savedList.questions.count else { return nil }
                
                self?.updateLists(solvedList: solvedList, savedList: savedList)
                return (solvedIds.map { Int($0) ?? -1 }.filter { $0 != -1 },
                        savedIds.map { Int($0) ?? -1 }.filter { $0 != -1 })
            }
            .filterNil()
            .withLatestFrom(questions.asObservable()) { (newList, oldList) -> (Set<Int>, Set<Int>, Set<Int>, Set<Int>) in
                let oldSolvedList = oldList.filter { $0.solved }.map { $0.id }
                let oldSavedList = oldList.filter { $0.saved }.map { $0.id }
                return (Set(newList.0),
                        Set(newList.1),
                        Set(oldSolvedList),
                        Set(oldSavedList))
            }
            .subscribe(onNext: { input in
                let (newSolvedList, newSavedList, oldSolvedList, oldSavedList) = input
                
                let indicesToUpdate = newSolvedList.union(newSavedList.union(oldSavedList.union(oldSolvedList)))
                
                guard !indicesToUpdate.isEmpty else { return }
                
                do {
                    let realmForRead = try Realm()
                    let realmForWrite = try Realm()
                    
                    try realmForWrite.write {
                        for index in indicesToUpdate {
                            if let model = realmForRead.object(ofType: Question.self, forPrimaryKey: index) {
                                model.solved = newSolvedList.contains(index)
                                model.saved = newSavedList.contains(index)
                            }
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateLists(solvedList: QuestionList, savedList: QuestionList) {
        let solvedIds = solvedList.questionIds.components(separatedBy: ",").filter { !$0.isEmpty }.map { Int($0) ?? -1 }.filter { $0 != -1 }
        let savedIds = savedList.questionIds.components(separatedBy: ",").filter { !$0.isEmpty }.map { Int($0) ?? -1 }.filter { $0 != -1 }
        
        do {
            let realmForWrite = try Realm()
            var savedQuestionList: [Question] = []
            for id in savedIds {
                if let model = realm.object(ofType: Question.self, forPrimaryKey: id) {
                    savedQuestionList.append(model)
                }
            }
            
            var solvedQuestionList: [Question] = []
            for id in solvedIds {
                if let model = realm.object(ofType: Question.self, forPrimaryKey: id) {
                    solvedQuestionList.append(model)
                }
            }
            
            try realmForWrite.write {
                solvedList.questions.append(objectsIn: solvedQuestionList)
                savedList.questions.append(objectsIn: savedQuestionList)
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
}
