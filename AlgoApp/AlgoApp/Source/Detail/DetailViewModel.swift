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

final class DetailViewModel {
    
    let detail: QuestionDetailModel
    let swiftSolution = BehaviorRelay<String?>(value: nil)
    let scrapingSolution = BehaviorRelay<Bool>(value: true)
    
    init(detail: QuestionDetailModel) {
        self.detail = detail
    }
    
    func scrapeSwiftSolution() {
        guard let url = URL(string:"https://github.com/soapyigu/LeetCode-Swift") else { return }
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
                    tds[0]["href"]?.contains(self.detail.titleSlug) == true,
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
    
    func markAsRead(_ read: Bool) {
        
    }
    
    func updateNote(_ note: String) {
        
    }
}
