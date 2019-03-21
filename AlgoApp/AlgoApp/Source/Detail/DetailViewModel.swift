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
        let languages: [Language] = [.swift, .java, .python, .javascript, .cPP]
        languages.forEach { language in
            let relay = scrapingProgressRelay(for: language)
            guard let titleSlug = detail.value?.titleSlug,
                let url = language.githubRepoUrl,
                let searchBlock = language.githubSearchBlock(with: titleSlug) else {
                    relay?.accept(false)
                    return
            }
            
            scraper.scrapeSolution(at: url, searchBlock: searchBlock, completionBlock: { [weak self] content in
                self?.githubSolutions[language] = content
                relay?.accept(false)
            }, failureBlock: { relay?.accept(false) })
        }
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
    
    func scrapingProgressRelay(for language: Language) -> BehaviorRelay<Bool>? {
        switch language {
        case .swift: return scrapingSwiftSolution
        case .java: return scrapingJavaSolution
        case .python: return scrapingPythonSolution
        case .javascript: return scrapingJavascriptSolution
        case .cPP: return scrapingCppSolution
        default: return nil
        }
    }
}
