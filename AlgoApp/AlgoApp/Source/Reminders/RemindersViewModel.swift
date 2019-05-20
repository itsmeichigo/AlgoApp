//
//  RemindersViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 3/10/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import RxCocoa
import RxRealm
import RxSwift

final class RemindersViewModel {
    let reminders = BehaviorRelay<[ReminderDetail]>(value: [])
    
    private let disposeBag = DisposeBag()
    private lazy var realm = try! Realm()
    
    func loadReminders() {
        Observable.collection(from: realm.objects(Reminder.self).filter(NSPredicate(format: "isDeleted = false")))
            .map { Array($0).map { ReminderDetail(with: $0) } }
            .bind(to: reminders)
            .disposed(by: disposeBag)
    }
    
    func toggleReminder(id: String) {
        let realm = try! Realm()
        guard let reminder = realm.object(ofType: Reminder.self, forPrimaryKey: id) else { return }
        let toggledValue = !reminder.enabled
        let reminderDate = reminder.date
        try! realm.write {
            if toggledValue && reminderDate < Date() && reminder.repeatDays.isEmpty {
                reminder.date = reminderDate.addingTimeInterval(24*60*60)
            }
            reminder.enabled = toggledValue
            NotificationHelper.shared.updateScheduledNotifications(for: ReminderDetail(with: reminder))
        }
    }
    
    func disableAllReminders() {
        let realm = try! Realm()
        let reminders = realm.objects(Reminder.self)
        try! realm.write {
            for reminder in reminders {
                reminder.enabled = false
                NotificationHelper.shared.updateScheduledNotifications(for: ReminderDetail(with: reminder))
            }
        }
    }
    
   func disableExpiredReminders() {
        let realm = try! Realm()
        let reminders = realm.objects(Reminder.self)
        try! realm.write {
            for reminder in reminders where reminder.repeatDays.isEmpty && reminder.date < Date() {
                reminder.enabled = false
            }
        }
    }
}
