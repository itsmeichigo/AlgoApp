//
//  QuestionList.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class QuestionList: Object {
    static let savedListId = "saved-list-id"
    static let solvedListId = "solved-list-id"
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var isCustom = false
    
    var questions = List<Question>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static var savedList: QuestionList? {
        let realm = try! Realm()
        return realm.object(ofType: QuestionList.self, forPrimaryKey: QuestionList.savedListId)
    }
    
    static var solvedList: QuestionList? {
        let realm = try! Realm()
        return realm.object(ofType: QuestionList.self, forPrimaryKey: QuestionList.solvedListId)
    }
    
    static func createCustomListsIfNeeded() {
        let realm = try! Realm()
        
        guard savedList == nil,
            solvedList == nil else { return }
        
        let newSolvedList = QuestionList()
        newSolvedList.id = QuestionList.solvedListId
        newSolvedList.name = "Solved Questions"
        newSolvedList.isCustom = true
        newSolvedList.questions.append(objectsIn: realm.objects(Question.self).filter(NSPredicate(format: "solved = true")).toArray())
        
        let newSavedList = QuestionList()
        newSavedList.id = QuestionList.savedListId
        newSavedList.name = "Saved Questions"
        newSavedList.isCustom = true
        newSavedList.questions.append(objectsIn: realm.objects(Question.self).filter(NSPredicate(format: "saved = true")).toArray())
        
        try! realm.write {
            realm.add([newSolvedList, newSavedList], update: true)
        }
    }
}
