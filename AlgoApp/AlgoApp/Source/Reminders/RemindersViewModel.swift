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
    private lazy var realmManager = RealmManager.shared
    
    func loadReminders() {
        realmManager.observableObjects(Reminder.self, filter: NSPredicate(format: "isDeleted = false"))
            .map { Array($0).map { ReminderDetail(with: $0) } }
            .do(onNext: { $0.forEach { NotificationHelper.shared.scheduleNotificationIfNeeded(for: $0) } })
            .bind(to: reminders)
            .disposed(by: disposeBag)
    }
    
    func toggleReminder(id: String) {
        guard let reminder = realmManager.object(Reminder.self, id: id) else { return }
        let toggledValue = !reminder.enabled
        let reminderDate = reminder.date
        
        realmManager.update {
            if toggledValue && reminderDate < Date() && reminder.repeatDays.isEmpty {
                reminder.date = reminderDate.addingTimeInterval(24*60*60)
            }
            reminder.enabled = toggledValue
            NotificationHelper.shared.updateScheduledNotifications(for: ReminderDetail(with: reminder))
        }
    }
    
    func disableAllReminders() {
        let reminders = realmManager.objects(Reminder.self)
        
        realmManager.update {
            for reminder in reminders {
                reminder.enabled = false
                NotificationHelper.shared.updateScheduledNotifications(for: ReminderDetail(with: reminder))
            }
        }
    }
    
   func disableExpiredReminders() {
        let reminders = realmManager.objects(Reminder.self)
    
        realmManager.update {
            for reminder in reminders where reminder.repeatDays.isEmpty && reminder.date < Date() {
                reminder.enabled = false
            }
        }
    }
}
