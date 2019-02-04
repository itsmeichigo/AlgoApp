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
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var isCustom = false
    
    var questions = List<Question>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
