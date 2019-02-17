//
//  QuestionDetailModel.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation

struct QuestionDetailModel {
    let id: Int
    let emoji: String?
    let title: String
    let tags: [String]
    let remark: String
    let difficulty: String
    let content: String
    let articleSlug: String
    let titleSlug: String
    
    private static let emojis = ["😈", "👹", "🤡", "💩", "👻", "👽", "👾", "🤖", "🎃", "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🐙", "🦑", "🐡", "🐳", "🌞", "🌝", "🌚", "🌈", "⛈", "🌤", "☃️", "🌊", "🍎", "🍐", "🍊", "🍋", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🍍", "🥥", "🥝", "🥑", "🥕", "🥓", "🌭", "🍕", "🌮", "🍝", "🍣", "🍙", "🍧", "🍦", "🍭", "🍫", "🍩", "🍵", "🥤", "🍸", "🚗", "✈️", "🚛", "🛵", "🚠", "🚂", "🚀", "🚁", "⛵️", "🎡", "🎢", "🎠", "🏰", "🔮", "🔫", "🎏", "🎹", "🥁", "🎸", "🎨", "🎪", "🧁", "🥪", "🥐", "🍄", "🌵", "🌲", "🍁", "🦄", "🐞", "🐝", "👑", "🧠", "💌", "📚", "🎈"]
    
    init(with question: Question) {
        id = question.id
        emoji = QuestionDetailModel.emojis.randomElement()
        title = question.title
        tags = Array(question.tags).map { $0.name }
        remark = question.remark
        difficulty = question.difficultyLevel.displayText
        content = question.content
        articleSlug = question.articleSlug
        titleSlug = question.titleSlug
    }
}
