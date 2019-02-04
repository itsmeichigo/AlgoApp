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

typealias QuestionFilter = (tags: [Tag], company: [Company])

protocol HomeViewModelType {
    var questions: BehaviorRelay<[QuestionCellModel]> { get }
    
    func loadSeedDatabase()
    func loadQuestions(filter: QuestionFilter?)
}

final class HomeViewModel: HomeViewModelType {
    
    let questions = BehaviorRelay<[QuestionCellModel]>(value: [])
    
    private let disposeBag = DisposeBag()
    private lazy var realm: Realm = {
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 2) {
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
        
        if !FileManager.default.fileExists(atPath: defaultRealmPath.path) {
            do {
                try FileManager.default.copyItem(atPath: bundleReamPath!, toPath: defaultRealmPath.path)
            } catch let error as NSError {
                print("error occurred, here are the details:\n \(error)")
            }
        }
    }
    
    func loadQuestions(filter: QuestionFilter?) {
        // FIXME: add predicate
        Observable.collection(from: realm.objects(Question.self))
            .map { Array($0).map { QuestionCellModel(with: $0) } }
            .bind(to: questions)
            .disposed(by: disposeBag)
    }
}
