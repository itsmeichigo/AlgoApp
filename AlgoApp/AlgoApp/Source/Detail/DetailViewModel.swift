//
//  DetailViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Kanna
import RealmSwift
import RxCocoa
import RxRealm
import RxSwift
import RxOptional

final class DetailViewModel {
    
    let detail = BehaviorRelay<QuestionDetailModel?>(value: nil)
    
    let swiftSolution = BehaviorRelay<String?>(value: nil)
    let scrapingSolution = BehaviorRelay<Bool>(value: true)
    
    private let realmForRead = try! Realm()
    private let realmForWrite = try! Realm()
    
    private let disposeBag = DisposeBag()
    private let scraper = SolutionScraper()
    private let questionId: Int
    
    init(questionId: Int) {
        self.questionId = questionId
        
        Observable.collection(from: realmForRead.objects(Question.self))
            .map { $0.first(where: { $0.id == questionId }) }
            .map { question -> QuestionDetailModel? in
                guard let question = question else { return nil }
                return QuestionDetailModel(with: question)
            }
            .bind(to: detail)
            .disposed(by: disposeBag)
    }
    
    func scrapeSwiftSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/soapyigu/LeetCode-Swift") else {
            scrapingSolution.accept(false)
            return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> (Bool, String?) in
            guard tds.count > 1 else { return (false, nil) }
            let found = tds[0]["href"]?.contains(titleSlug) == true
            let path = tds[1]["href"]
            return (found, path)
        }, completionBlock: { [weak self] content in
            self?.scrapingSolution.accept(false)
            self?.swiftSolution.accept(content)
        }, failureBlock: { [weak self] in
            self?.scrapingSolution.accept(false)
        })
    }
    
    func toggleRead() {
        guard let question = realmForWrite.object(ofType: Question.self, forPrimaryKey: questionId) else { return }
        let toggledValue = !question.read
        try! realmForWrite.write {
            question.read = toggledValue
        }
    }
    
    func updateNote(_ note: String, language: Language) {
        guard let question = realmForWrite.object(ofType: Question.self, forPrimaryKey: questionId) else { return }
        try! realmForWrite.write {
            question.note = note
            question.noteLanguage = language.rawValue
        }
    }
}
