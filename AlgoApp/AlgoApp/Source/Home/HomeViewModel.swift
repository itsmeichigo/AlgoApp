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
        var predicates: [NSPredicate] = []
        var results = realm.objects(Question.self)
        if let query = query, !query.isEmpty {
            let predicate = NSPredicate(format: "title contains %@", query)
            predicates.append(predicate)
        }
        
        if let tags = filter?.tags, !tags.isEmpty {
            let tagPredicate = NSPredicate(format: "ANY tags.name IN %@", tags)
            predicates.append(tagPredicate)
        }
        
        if let companies = filter?.companies, !companies.isEmpty {
            let companyPredicate = NSPredicate(format: "ANY companies.name IN %@", companies)
            predicates.append(companyPredicate)
        }
        
        if let levels = filter?.levels, !levels.isEmpty {
            let levelPredicate = NSPredicate(format: "rawDifficultyLevel IN %@", levels.map { $0.rawValue })
            predicates.append(levelPredicate)
        }
        
        let topLikedPredicate = NSPredicate(format: "topLiked = true")
        let topInterviewPredicate = NSPredicate(format: "topInterview = true")
        if filter?.topLiked == true && filter?.topInterviewed == true {
            let compound = NSCompoundPredicate(type: .or, subpredicates: [topLikedPredicate, topInterviewPredicate])
            predicates.append(compound)
        } else if filter?.topLiked == true {
            predicates.append(topLikedPredicate)
        } else if filter?.topInterviewed == true {
            predicates.append(topInterviewPredicate)
        }
        
        if predicates.count > 0 {
            let compound = NSCompoundPredicate(type: .and, subpredicates: predicates)
            results = realm.objects(Question.self).filter(compound)
        }
        
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
