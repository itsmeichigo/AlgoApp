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
        note = question.note
        noteLanguage = Language(rawValue: question.noteLanguage) ?? .markdown
    }
}
