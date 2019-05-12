//
//  QuestionDetailModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation

struct QuestionCellModel {
    let id: Int
    let emoji: String?
    let title: String
    let tags: [String]
    let remark: String
    let difficulty: String
    let rawDifficultyLevel: Int
    let solved: Bool
    
    init(with question: Question) {
        id = question.id
        emoji = question.emoji
        title = question.title
        tags = Array(question.tags).map { $0.name }
        remark = question.remark
        difficulty = question.difficultyLevel.displayText
        rawDifficultyLevel = question.rawDifficultyLevel
        solved = question.solved
    }
}
