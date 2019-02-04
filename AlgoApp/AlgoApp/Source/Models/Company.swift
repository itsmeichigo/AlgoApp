//
//  Company.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class Company: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
