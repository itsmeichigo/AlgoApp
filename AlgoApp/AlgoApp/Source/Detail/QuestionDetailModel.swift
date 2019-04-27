//
//  QuestionDetailModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation

struct QuestionDetailModel {
    let id: Int
    let title: String
    let tags: [String]
    let remark: String
    let difficulty: String
    let content: String
    let articleSlug: String
    let titleSlug: String
    let solved: Bool
    let saved: Bool
    let note: String
    let noteLanguage: Language
    let githubSolutions: [Language: String]
    
    init(with question: Question) {
        id = question.id
        title = question.title
        tags = Array(question.tags).map { $0.name }
        remark = question.remark
        difficulty = question.difficultyLevel.displayText
        content = question.content
        articleSlug = question.articleSlug
        titleSlug = question.titleSlug
        solved = question.solved
        saved = question.saved
        note = question.note?.content ?? ""
        if let language = question.note?.language {
            noteLanguage = Language(rawValue: language) ?? .markdown
        } else {
            noteLanguage = .markdown
        }
        
        if let solution = question.solution {
            var contents: [Language: String] = [:]
            if let swiftContent = solution.swiftSolution {
                contents[.swift] = swiftContent
            }
            
            if let pythonContent = solution.pythonSolution {
                contents[.python] = pythonContent
            }
            
            if let javascriptContent = solution.javascriptSolution {
                contents[.javascript] = javascriptContent
            }
            
            if let javaContent = solution.javaSolution {
                contents[.java] = javaContent
            }
            
            if let cppContent = solution.cppSolution {
                contents[.cPP] = cppContent
            }
            
            githubSolutions = contents
            
        } else {
            githubSolutions = [:]
        }
    }
}
