//
//  Tag.swift
//  Scraper
//
//  Created by Huong Do on 1/31/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class Tag: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var name = ""
    @objc dynamic var slug = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}
