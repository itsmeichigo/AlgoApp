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
    private lazy var realm: Realm = {
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 4) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        Realm.Configuration.defaultConfiguration = config
        
        return try! Realm()
    }()
    
    func loadSeedDatabase() {
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
        let bundleReamPath = Bundle.main.path(forResource: "default", ofType:"realm")
        
        guard !FileManager.default.fileExists(atPath: defaultRealmPath.path) else { return }
        
        do {
            try FileManager.default.copyItem(atPath: bundleReamPath!, toPath: defaultRealmPath.path)
        } catch let error as NSError {
            print("error occurred, here are the details:\n \(error)")
        }
    }
    
    func loadQuestions(query: String?, filter: QuestionFilter?) {
        let results = Question.loadQuestions(with: realm, query: query, filter: filter)
        
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
