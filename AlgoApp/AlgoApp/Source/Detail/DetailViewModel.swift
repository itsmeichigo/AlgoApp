//
//  DetailViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Kanna
import RxCocoa
import RxSwift
import RxOptional

final class DetailViewModel {
    
    let detail = BehaviorRelay<QuestionDetailModel?>(value: nil)
    let githubSolutionsRelay = BehaviorRelay<[Language: String]>(value: [:])
    let scrapingSolutions = BehaviorRelay<Bool>(value: true)
    
    private let realmManager = RealmManager.shared
    
    private let disposeBag = DisposeBag()
    private let scraper = SolutionScraper()
    private var questionId = BehaviorRelay<Int>(value: 0)
    
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
    
    init(question id: Int) {
        questionId.accept(id)
        
        Observable.combineLatest(realmManager.observableObjects(Question.self), questionId) { $1 }
            .map { [weak self] in self?.realmManager.object(Question.self, id: $0) }
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
    
    func updateDetails(with questionId: Int) {
        self.questionId.accept(questionId)
    }
    
    func scrapeSolutions(detail: QuestionDetailModel) {
        githubSolutions = detail.githubSolutions
        
        let allLanguages: Set<Language> = [.swift, .java, .python, .javascript, .cPP]
        let currentLanguages = Set(Array(detail.githubSolutions.keys))
        
        let missingLanguages = allLanguages.subtracting(currentLanguages)
        
        scrapingCppSolution.accept(!githubSolutions.keys.contains(.cPP))
        scrapingJavaSolution.accept(!githubSolutions.keys.contains(.java))
        scrapingSwiftSolution.accept(!githubSolutions.keys.contains(.swift))
        scrapingPythonSolution.accept(!githubSolutions.keys.contains(.python))
        scrapingJavascriptSolution.accept(!githubSolutions.keys.contains(.javascript))
        
        missingLanguages.forEach { language in
            let relay = scrapingProgressRelay(for: language)
            let titleSlug = detail.titleSlug
            let questionId = detail.id
            
            guard let url = language.githubRepoUrl,
                let searchBlock = language.githubSearchBlock(with: titleSlug) else {
                    relay?.accept(false)
                    return
            }
            
            scraper.scrapeSolution(at: url, for: questionId, searchBlock: searchBlock, completionBlock: { [weak self] content in
                if self?.detail.value?.id != questionId { return }
                self?.githubSolutions[language] = content
                self?.saveSolution(for: questionId, content: content, language: language)
                relay?.accept(false)
            }, failureBlock: { relay?.accept(false) })
        }
    }
    
    func toggleSolved() {
        guard let question = realmManager.object(Question.self, id: questionId.value) else { return }
        let toggledValue = !question.solved
        
        realmManager.update {
            question.solved = toggledValue
            let solvedList = QuestionList.solvedList
            let questionList = solvedList.questions
            if toggledValue {
                solvedList.questions.append(question)
                solvedList.questionIds = (questionList + [question])
                    .map { "\($0.id)" }
                    .joined(separator: ",")
            } else if let index = solvedList.questions.firstIndex(where: { $0.id == question.id }) {
                solvedList.questions.remove(at: index)
                solvedList.questionIds = questionList
                    .filter { $0.id != question.id }
                    .map { "\($0.id)" }
                    .joined(separator: ",")
            }
        }
    }
    
    func toggleSaved() {
        guard let question = realmManager.object(Question.self, id: questionId.value) else { return }
        let toggledValue = !question.saved
        
        realmManager.update {
            question.saved = toggledValue
            let savedList = QuestionList.savedList
            let questionList = savedList.questions
            
            if toggledValue &&
                (savedList.questions.filter { $0.id == question.id }).isEmpty {
                savedList.questions.append(question)
                savedList.questionIds = Set(questionList + [question])
                    .map { "\($0.id)" }
                    .joined(separator: ",")
                
            } else if !toggledValue,
                let index = savedList.questions.firstIndex(where: { $0.id == question.id }) {
                savedList.questions.remove(at: index)
                savedList.questionIds = Set(questionList)
                    .filter { $0.id != question.id }
                    .map { "\($0.id)" }
                    .joined(separator: ",")
            }
        }
    }
    
    func updateNote(_ content: String, language: Language) {
        guard let question = realmManager.object(Question.self, id: questionId.value) else { return }
        
        realmManager.update {
            if let note = question.note {
                note.content = content
                note.language = language.rawValue
                note.questionId = question.id
                note.questionTitle = question.title
                question.note = note
            } else {
                let note = Note()
                note.content = content
                note.language = language.rawValue
                note.questionId = question.id
                note.questionTitle = question.title
                question.note = note
            }
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
    
    func saveSolution(for questionId: Int, content: String, language: Language) {
        
        if let question = realmManager.object(Question.self, id: questionId) {
            realmManager.update {
                if let solution = question.solution {
                    switch language {
                    case .cPP:
                        solution.cppSolution = content
                    case .java:
                        solution.javaSolution = content
                    case .javascript:
                        solution.javascriptSolution = content
                    case .python:
                        solution.pythonSolution = content
                    case .swift:
                        solution.swiftSolution = content
                    default:
                        break
                    }
                } else {
                    let solution = Solution()
                    switch language {
                    case .cPP:
                        solution.cppSolution = content
                    case .java:
                        solution.javaSolution = content
                    case .javascript:
                        solution.javascriptSolution = content
                    case .python:
                        solution.pythonSolution = content
                    case .swift:
                        solution.swiftSolution = content
                    default:
                        break
                    }
                    question.solution = solution
                }
            }
        }
    }
}
