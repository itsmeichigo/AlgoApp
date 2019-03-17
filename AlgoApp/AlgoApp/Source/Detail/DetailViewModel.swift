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
    let githubSolutionsRelay = BehaviorRelay<[Language: String]>(value: [:])
    let scrapingSolutions = BehaviorRelay<Bool>(value: true)
    
    private let realmForRead = try! Realm()
    private let realmForWrite = try! Realm()
    
    private let disposeBag = DisposeBag()
    private let scraper = SolutionScraper()
    private let questionId: Int
    
    private let scrapingSwiftSolution = BehaviorRelay<Bool>(value: true)
    private let scrapingJavaSolution = BehaviorRelay<Bool>(value: true)
    private let scrapingJavascriptSolution = BehaviorRelay<Bool>(value: true)
    private let scrapingPythonSolution = BehaviorRelay<Bool>(value: true)
    private let scrapingCppSolution = BehaviorRelay<Bool>(value: true)
    
    private var githubSolutions: [Language: String] = [:] {
        didSet {
            githubSolutionsRelay.accept(githubSolutions)
        }
    }
    
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
        
        Observable.combineLatest(scrapingSwiftSolution, scrapingJavaSolution, scrapingCppSolution, scrapingPythonSolution, scrapingJavascriptSolution)
            .map { $0.0 || $0.1 || $0.2 || $0.3 || $0.4 }
            .bind(to: scrapingSolutions)
            .disposed(by: disposeBag)
    }
    
    func scrapeSolutions() {
        scrapeSwiftSolution()
        scrapeJavaSolution()
        scrapePythonSolution()
        scrapeJavascriptSolution()
        scrapeCppSolution()
    }
    
    func toggleSolved() {
        guard let question = realmForWrite.object(ofType: Question.self, forPrimaryKey: questionId) else { return }
        let toggledValue = !question.solved
        try! realmForWrite.write {
            question.solved = toggledValue
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

private extension DetailViewModel {
    
    func scrapeSwiftSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/soapyigu/LeetCode-Swift") else {
                scrapingSwiftSolution.accept(false)
                return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> String? in
            guard tds.count > 1 &&
                tds[0]["href"]?.contains(titleSlug) == true else { return nil }
            return tds[1]["href"]
        }, completionBlock: { [weak self] content in
            self?.scrapingSwiftSolution.accept(false)
            self?.githubSolutions[.swift] = content
            }, failureBlock: { [weak self] in
                self?.scrapingSwiftSolution.accept(false)
        })
    }
    
    func scrapeJavaSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/fishercoder1534/Leetcode") else {
                scrapingJavaSolution.accept(false)
                return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> String? in
            guard tds.count > 1 &&
                tds[0]["href"]?.contains(titleSlug) == true else { return nil }
            return tds[1]["href"]
        }, completionBlock: { [weak self] content in
            self?.scrapingJavaSolution.accept(false)
            self?.githubSolutions[.java] = content
        }, failureBlock: { [weak self] in
            self?.scrapingJavaSolution.accept(false)
        })
    }
    
    func scrapePythonSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/Garvit244/Leetcode") else {
                scrapingPythonSolution.accept(false)
                return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> String? in
            guard tds.count > 1 &&
                tds[0]["href"]?.contains(titleSlug) == true else { return nil }
            return tds[1]["href"]
        }, completionBlock: { [weak self] content in
            self?.scrapingPythonSolution.accept(false)
            self?.githubSolutions[.python] = content
        }, failureBlock: { [weak self] in
            self?.scrapingPythonSolution.accept(false)
        })
    }
    
    func scrapeJavascriptSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/hanzichi/leetcode") else {
                scrapingJavascriptSolution.accept(false)
                return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> String? in
            guard tds.count > 1 &&
                tds[0]["href"]?.contains(titleSlug) == true else { return nil }
            return tds[1]["href"]
        }, completionBlock: { [weak self] content in
            self?.scrapingJavascriptSolution.accept(false)
            self?.githubSolutions[.javascript] = content
        }, failureBlock: { [weak self] in
            self?.scrapingJavascriptSolution.accept(false)
        })
    }
    
    func scrapeCppSolution() {
        guard let titleSlug = detail.value?.titleSlug,
            let url = URL(string: "https://github.com/haoel/leetcode") else {
                scrapingCppSolution.accept(false)
                return
        }
        
        scraper.scrapeSolution(at: url, searchBlock: { tds -> String? in
            guard tds.count > 1 &&
                tds[0]["href"]?.contains(titleSlug) == true else { return nil }
            return tds[1]["href"]
        }, completionBlock: { [weak self] content in
            self?.scrapingCppSolution.accept(false)
            self?.githubSolutions[.cPP] = content
            }, failureBlock: { [weak self] in
                self?.scrapingCppSolution.accept(false)
        })
    }
}
