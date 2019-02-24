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
            let url = URL(string:"https://github.com/soapyigu/LeetCode-Swift") else {
            scrapingSolution.accept(false)
            return
        }
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let data = data,
                let doc = try? Kanna.HTML(html: data, encoding: String.Encoding.utf8),
                let nodes = doc.body?.xpath("//tr").enumerated() else {
                    self.scrapingSolution.accept(false)
                    return
            }
            
            var found = false
            for node in nodes {
                let offset = node.offset
                let tds = node.element.xpath("//tr[\(offset)]/td/a")
                
                if tds.count > 1,
                    tds[0]["href"]?.contains(titleSlug) == true,
                    let path = tds[1]["href"] {
                    if let url = URL(string: "https://github.com" + path) {
                        found = true
                        self.scrapeSwiftContent(url: url)
                    }
                    break
                }
            }
            
            if !found { self.scrapingSolution.accept(false) }
        }
        task.resume()
    }
    
    private func scrapeSwiftContent(url: URL) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let data = data,
                let doc = try? Kanna.HTML(html: data, encoding: String.Encoding.utf8),
                let node = doc.body?.xpath("//*[@id='raw-url']").first,
                let path = node["href"], let url = URL(string: "https://github.com" + path) else {
                    
                self.scrapingSolution.accept(false)
                return
            }
            
            DispatchQueue.global().async {
                if let content = try? String(contentsOf: url) {
                    self.swiftSolution.accept(content)
                    self.scrapingSolution.accept(false)
                } else {
                    self.scrapingSolution.accept(false)
                }
            }
        }
        task.resume()
    }
    
    func toggleRead() {
        guard let question = realmForWrite.object(ofType: Question.self, forPrimaryKey: questionId) else { return }
        let toggledValue = !question.read
        try! realmForWrite.write {
            question.read = toggledValue
        }
    }
    
    func updateNote(_ note: String) {
        
    }
}
