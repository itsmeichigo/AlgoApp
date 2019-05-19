//
//  Solution.swift
//  AlgoApp
//
//  Created by Huong Do on 4/27/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class Solution: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var swiftSolution: String?
    @objc dynamic var javascriptSolution: String?
    @objc dynamic var javaSolution: String?
    @objc dynamic var pythonSolution: String?
    @objc dynamic var cppSolution: String?
    override static func primaryKey() -> String? {
        return "id"
    }
}
