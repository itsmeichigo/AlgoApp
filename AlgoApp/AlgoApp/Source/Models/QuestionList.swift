//
//  QuestionList.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream

final class QuestionList: Object, IdentifiableObject, CKRecordRecoverable, CKRecordConvertible {
    
    static let savedListId = "saved-list-id"
    static let solvedListId = "solved-list-id"
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var isCustom = false
    @objc dynamic var isDeleted = false
    @objc dynamic var questionIds = ""
    
    var questions = List<Question>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static var savedList: QuestionList? {
        return RealmManager.shared.object(QuestionList.self, id: QuestionList.savedListId)
    }
    
    static var solvedList: QuestionList? {
        return RealmManager.shared.object(QuestionList.self, id: QuestionList.solvedListId)
    }
    
    static func createCustomListsIfNeeded() {
        let realmManager = RealmManager.shared
        
        guard savedList == nil,
            solvedList == nil else { return }
        
        let newSolvedList = QuestionList()
        newSolvedList.id = QuestionList.solvedListId
        newSolvedList.name = "Solved Questions"
        newSolvedList.isCustom = true
        newSolvedList.questions.append(objectsIn: realmManager.objects(Question.self, filter: NSPredicate(format: "solved = true")))
        
        let newSavedList = QuestionList()
        newSavedList.id = QuestionList.savedListId
        newSavedList.name = "Saved Questions"
        newSavedList.isCustom = true
        newSavedList.questions.append(objectsIn: realmManager.objects(Question.self, filter: NSPredicate(format: "saved = true")).toArray())
        
        realmManager.create(objects: [newSolvedList, newSavedList], update: true)
    }
}
