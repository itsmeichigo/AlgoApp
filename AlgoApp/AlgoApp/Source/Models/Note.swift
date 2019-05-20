//
//  Note.swift
//  AlgoApp
//
//  Created by Huong Do on 4/7/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import IceCream

final class Note: Object, CKRecordConvertible, CKRecordRecoverable {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var content = ""
    @objc dynamic var language = "Markdown"
    @objc dynamic var lastUpdated = Date()
    @objc dynamic var questionId = -1
    @objc dynamic var questionTitle = ""
    @objc dynamic var isDeleted = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
