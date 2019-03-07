//
//  SolutionScraper.swift
//  AlgoApp
//
//  Created by Huong Do on 3/6/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Kanna

final class SolutionScraper {
    
    func scrapeSolution(at url: URL,
                        searchBlock: @escaping ((Kanna.XPathObject) -> String?),
                        completionBlock: @escaping ((String) -> Void),
                        failureBlock: @escaping (() -> Void)) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                let data = data,
                let doc = try? Kanna.HTML(html: data, encoding: String.Encoding.utf8),
                let nodes = doc.body?.xpath("//tr").enumerated() else {
                    failureBlock()
                    return
            }
            
            var found = false
            for (offset, node) in nodes {
                let tds = node.xpath("//tr[\(offset)]/td/a")
                
                let result = searchBlock(tds)
                if let path = result?.replacingOccurrences(of: " ", with: "%20") {
                    if path.contains("https://github.com"), let url = URL(string: path) {
                        found = true
                        self.scrapeContent(url: url, completionBlock: completionBlock, failureBlock: failureBlock)
                    } else if let url = URL(string: "https://github.com" + path) {
                        found = true
                        self.scrapeContent(url: url, completionBlock: completionBlock, failureBlock: failureBlock)
                    }
                    break
                }
            }
            
            if !found { failureBlock() }
        }
        task.resume()
    }
    
    private func scrapeContent(url: URL,
                               completionBlock: @escaping ((String) -> Void),
                               failureBlock: @escaping (() -> Void)) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let data = data,
                let doc = try? Kanna.HTML(html: data, encoding: String.Encoding.utf8),
                let node = doc.body?.xpath("//*[@id='raw-url']").first,
                let path = node["href"], let url = URL(string: "https://github.com" + path) else {
                    
                    failureBlock()
                    return
            }
            
            DispatchQueue.global().async {
                if let content = try? String(contentsOf: url) {
                    completionBlock(content)
                } else {
                    failureBlock()
                }
            }
        }
        task.resume()
    }
}
