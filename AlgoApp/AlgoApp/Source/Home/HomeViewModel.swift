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
    
    private let disposeBag = DisposeBag()
    private lazy var realm = try! Realm()
    
    func loadQuestions(query: String?, filter: QuestionFilter?, onlyUnsolved: Bool) {
        let results = Question.loadQuestions(with: realm, query: query, filter: filter, onlyUnsolved: onlyUnsolved)
        
        Observable.collection(from: results)
            .map { Array($0)
                .map { QuestionCellModel(with: $0) }
                .sorted(by: { $0.id < $1.id })
            }
            .bind(to: questions)
            .disposed(by: disposeBag)
    }
    
    func randomDetailModel() -> DetailViewModel {
        let randomIndex = Int.random(in: 0..<questions.value.count)
        let question = questions.value[randomIndex]
        return DetailViewModel(questionId: question.id)
    }
}
