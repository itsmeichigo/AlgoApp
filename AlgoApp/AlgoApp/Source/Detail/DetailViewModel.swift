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
    let swiftSolutionUrl = BehaviorRelay<URL?>(value: nil)
    
    init(detail: QuestionDetailModel) {
        self.detail = detail
    }
    
    func scrapeSwiftSolution() {
        guard let url = URL(string:"https://github.com/soapyigu/LeetCode-Swift") else { return }
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            guard let data = data,
                let doc = try? Kanna.HTML(html: data, encoding: String.Encoding.utf8) else { return }
            guard let nodes = doc.body?.xpath("//tr").enumerated() else { return }
            
            for node in nodes {
                let offset = node.offset
                let tds = node.element.xpath("//tr[\(offset)]/td/a")
                
                if tds.count > 1,
                    tds[0]["href"]?.contains(self.detail.titleSlug) == true,
                    let path = tds[1]["href"] {
                    self.swiftSolutionUrl.accept(URL(string: "https://github.com" + path))
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
