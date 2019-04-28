//
//  ReminderDetailViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 3/10/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift

final class ReminderDetailViewModel {
    let reminder: ReminderDetail?
    
    private let realm = try! Realm()
    
    init(reminder: ReminderDetail?) {
        self.reminder = reminder
    }
    
    func saveReminder(date: Date, repeatDays: [Int], filter: QuestionFilter?) {
        let reminder = Reminder()
        if let id = self.reminder?.id {
            reminder.id = id
        }
        reminder.date = correctSecondComponent(date: date)
        reminder.repeatDays.append(objectsIn: repeatDays)
        if let filter = filter {
            reminder.filter = FilterObject(with: filter)
        }
        
        try! realm.write {
            realm.add(reminder, update: true)
            NotificationHelper.shared.updateScheduledNotifications(for: ReminderDetail(with: reminder))
        }
    }
    
    func deleteReminder() {
        guard let detail = reminder,
            let model = realm.object(ofType: Reminder.self, forPrimaryKey: detail.id) else { return }
        NotificationHelper.shared.cancelScheduledNotifications(for: detail, completionHandler: {})
        try! realm.write {
            realm.delete(model)
        }
    }
    
    func countProblems(with filter: QuestionFilter?, onlyUnsolved: Bool) -> Int {
        return Question.loadQuestions(filter: filter, onlyUnsolved: onlyUnsolved).count
    }
    
    private func correctSecondComponent(date: Date, calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)) -> Date {
        let second = calendar.component(.second, from: date)
        let updatedDate = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.second,
                                                        value: -second,
                                                        to: date,
                                                        options:.matchStrictly)!
        if updatedDate < Date() {
            return updatedDate.addingTimeInterval(24*60*60)
        }
        return updatedDate
    }
}
