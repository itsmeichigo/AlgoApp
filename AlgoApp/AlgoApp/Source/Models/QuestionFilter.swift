//
//  QuestionFilter.swift
//  AlgoApp
//
//  Created by Huong Do on 3/10/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

struct QuestionFilter {
    let tags: [String]
    let companies: [String]
    let levels: [Question.DifficultyLevel]
    let topLiked: Bool
    let topInterviewed: Bool
}

final class FilterObject: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var topLiked: Bool = false
    @objc dynamic var topInterviewed: Bool = false
    
    let tags = List<String>()
    let companies = List<String>()
    let levels = List<Int>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(with filter: QuestionFilter) {
        self.init()
        tags.append(objectsIn: filter.tags)
        companies.append(objectsIn: filter.companies)
        levels.append(objectsIn: filter.levels.map { $0.rawValue })
        topLiked = filter.topLiked
        topInterviewed = filter.topInterviewed
    }
    
    func toFilterStruct() -> QuestionFilter {
        return QuestionFilter(tags: tags.toArray(),
                              companies: companies.toArray(),
                              levels: levels.map { Question.DifficultyLevel(rawValue: $0) ?? .easy },
                              topLiked: topLiked,
                              topInterviewed: topInterviewed)
    }
}
