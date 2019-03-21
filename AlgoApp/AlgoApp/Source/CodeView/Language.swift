//
//  Language.swift
//  AlgoApp
//
//  Created by Huong Do on 3/21/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import Kanna

enum Language: String, CaseIterable {
    case c = "C"
    case cSharp = "C#"
    case cPP = "C++"
    case go = "Go"
    case java = "Java"
    case javascript = "Javascript"
    case markdown = "Markdown"
    case objc = "Objective-C"
    case php = "PHP"
    case python = "Python"
    case ruby = "Ruby"
    case swift = "Swift"
    
    var rawLanguageName: String {
        switch self {
        case .objc:
            return "objectivec"
        case .cSharp:
            return "cs"
        default:
            return self.rawValue.lowercased()
        }
    }
    
    var githubRepoUrl: URL? {
        switch self {
        case .swift:
            return URL(string:"https://github.com/soapyigu/LeetCode-Swift")
        case .java:
            return URL(string:"https://github.com/fishercoder1534/Leetcode")
        case .python:
            return URL(string:"https://github.com/Garvit244/Leetcode")
        case .javascript:
            return URL(string:"https://github.com/hanzichi/leetcode")
        case .cPP:
            return URL(string:"https://github.com/haoel/leetcode")
        default:
            return nil
        }
    }
    
    func githubSearchBlock(with titleSlug: String) -> ((Kanna.XPathObject) -> String?)? {
        switch self {
        case .swift, .java, .python, .javascript, .cPP:
            return { tds -> String? in
                guard tds.count > 1 &&
                    tds[0]["href"]?.contains(titleSlug) == true else { return nil }
                return tds[1]["href"]
            }
        default:
            return nil
        }
    }
}
