//
//  Reminder.swift
//  AlgoApp
//
//  Created by Huong Do on 3/10/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

struct ReminderDetail {
    let id: String
    let date: Date
    let filter: QuestionFilter?
    let enabled: Bool
    let repeatDays: [Int]
    
    init(with reminder: Reminder) {
        id = reminder.id
        date = reminder.date
        filter = reminder.filter?.toFilterStruct()
        enabled = reminder.enabled
        repeatDays = reminder.repeatDays.toArray()
    }
}

extension ReminderDetail {
    var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm"
        return dateFormatter.string(from: self.date)
    }
    
    var ampm: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "a"
        return dateFormatter.string(from: self.date)
    }
    
    var filterString: String {
        if let filter = filter {
            return filter.allFilters.isEmpty ? "Any problems 💁‍♀️" : filter.allFilters.joined(separator: "・")
        }
        return "Any problems 💁‍♀️"
    }
    
    var repeatDaysString: String {
        if repeatDays.count == 7 {
            return "🤖 Everyday"
        } else if repeatDays.count == 5 &&
            !repeatDays.contains(1) &&
            !repeatDays.contains(7) {
            return "💼 Weekdays"
        } else if repeatDays.count == 2 &&
            repeatDays.contains(1) &&
            repeatDays.contains(7) {
            return "🏠 Weekends"
        } else if repeatDays.count > 0 {
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return "🗓 " + repeatDays.sorted()
                .map { days[$0 - 1] }
                .joined(separator: ", ")
        }
        return ""
    }
    
}

final class Reminder: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var date: Date = Date()
    @objc dynamic var filter: FilterObject? = nil
    @objc dynamic var enabled: Bool = true
    
    let repeatDays = List<Int>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func randomQuestionId(for reminderId: String) -> Int? {
        let realm = try! Realm()
        guard let reminder = realm.object(ofType: Reminder.self, forPrimaryKey: reminderId) else { return nil }
        
        return Question.loadQuestions(with: realm,
                                      filter: ReminderDetail(with: reminder).filter,
                                      onlyUnsolved: AppConfigs.shared.hidesSolvedProblems).randomElement()?.id
    }
}
