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

typealias QuestionFilter = (query: String, tags: [Tag], companies: [Company])

protocol HomeViewModelType {
    var questions: BehaviorRelay<[QuestionDetailModel]> { get }
    
    func loadSeedDatabase()
    func loadQuestions(filter: QuestionFilter?)
}

final class HomeViewModel: HomeViewModelType {
    
    let questions = BehaviorRelay<[QuestionDetailModel]>(value: [])
    
    private let disposeBag = DisposeBag()
    private lazy var realm: Realm = {
        let config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 3) {
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
    
    func loadQuestions(filter: QuestionFilter?) {
        var predicates: [NSPredicate] = []
        var results = realm.objects(Question.self)
        if let query = filter?.query, !query.isEmpty {
            let predicate = NSPredicate(format: "title contains %@", query)
            predicates.append(predicate)
        }
        
        if predicates.count > 0 {
            let compound = NSCompoundPredicate(type: .and, subpredicates: predicates)
            results = realm.objects(Question.self).filter(compound)
        }
        
        Observable.collection(from: results)
            .map { Array($0)
                .map { QuestionDetailModel(with: $0) }
                .sorted(by: { $0.id < $1.id })
            }
            .bind(to: questions)
            .disposed(by: disposeBag)
    }
}
