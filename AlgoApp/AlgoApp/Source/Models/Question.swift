//
//  Problem.swift
//  Scraper
//
//  Created by Huong Do on 1/29/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class Question: Object, IdentifiableObject {    
    @objc dynamic var id = 0
    @objc dynamic var title = ""
    @objc dynamic var content = ""
    @objc dynamic var articleSlug = ""
    @objc dynamic var titleSlug = ""
    @objc dynamic var rawDifficultyLevel = 1
    
    @objc dynamic var topLiked = false
    @objc dynamic var topInterview = false
    @objc dynamic var saved = false
    
    @objc dynamic var solved = false
    @objc dynamic var emoji = ""
    
    @objc dynamic var note: Note?
    @objc dynamic var solution: Solution?
    
    var tags = List<Tag>()
    var companies = List<Company>()
    
    var paidOnly = false
    var difficultyLevel: DifficultyLevel {
        return DifficultyLevel(rawValue: rawDifficultyLevel) ?? .easy
    }
    
    var remark: String {
        if topLiked && topInterview {
            return "Top 👍 & 👨‍💻"
        }
        return topLiked ? Remarks.topLiked.displayText : topInterview ? Remarks.topInterviewed.displayText : ""
    }
    
    enum Remarks: CaseIterable {
        case topLiked
        case topInterviewed
        
        var title: String {
            switch self {
            case .topLiked: return "Top Liked"
            case .topInterviewed: return "Top Interviewed"
            }
        }
        
        var displayText: String {
            switch self {
            case .topLiked: return "👍 Top Liked"
            case .topInterviewed: return "👨‍💻 Top Interviewed"
            }
        }
    }
    
    enum DifficultyLevel: Int, CaseIterable {
        case easy = 1
        case medium = 2
        case hard = 3
        
        var title: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
        
        var displayText: String {
            switch self {
            case .easy: return "🎖"
            case .medium: return "🎖🎖"
            case .hard: return "🎖🎖🎖"
            }
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }

}

extension Question {
    static func loadQuestions(with realmManager: RealmManager, query: String? = nil, filter: QuestionFilter? = nil, onlyUnsolved: Bool = false) -> Results<Question> {
        var predicates: [NSPredicate] = []
        var results = realmManager.objects(Question.self)
        if let query = query, !query.isEmpty {
            let predicate = NSPredicate(format: "title contains[cd] %@", query)
            predicates.append(predicate)
        }
        
        if let tags = filter?.tags, !tags.isEmpty {
            let tagPredicate = NSPredicate(format: "ANY tags.name IN %@", tags)
            predicates.append(tagPredicate)
        }
        
        if let companies = filter?.companies, !companies.isEmpty {
            let companyPredicate = NSPredicate(format: "ANY companies.name IN %@", companies)
            predicates.append(companyPredicate)
        }
        
        if let levels = filter?.levels, !levels.isEmpty {
            let levelPredicate = NSPredicate(format: "rawDifficultyLevel IN %@", levels)
            predicates.append(levelPredicate)
        }
        
        let topLikedPredicate = NSPredicate(format: "topLiked = true")
        let topInterviewPredicate = NSPredicate(format: "topInterview = true")
        if filter?.topLiked == true && filter?.topInterviewed == true {
            let compound = NSCompoundPredicate(type: .and, subpredicates: [topLikedPredicate, topInterviewPredicate])
            predicates.append(compound)
        } else if filter?.topLiked == true {
            predicates.append(topLikedPredicate)
        } else if filter?.topInterviewed == true {
            predicates.append(topInterviewPredicate)
        }
        
        if filter?.saved == true {
            let savedPredicate = NSPredicate(format: "saved = true")
            predicates.append(savedPredicate)
        }
        
        if onlyUnsolved {
            let unsolvedPredicate = NSPredicate(format: "solved = false")
            predicates.append(unsolvedPredicate)
        }
        
        if predicates.count > 0 {
            let compound = NSCompoundPredicate(type: .and, subpredicates: predicates)
            results = realmManager.objects(Question.self).filter(compound)
        }
        
        return results
    }
}

