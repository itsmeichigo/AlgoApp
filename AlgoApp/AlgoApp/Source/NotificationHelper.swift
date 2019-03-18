//
//  Scheduler.swift
//  AlgoApp
//
//  Created by Huong Do on 3/17/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

struct NotificationHelper {
    
    private static let openProblemActionId = "com.ichigo.AlgoApp.reminders.problem"
    private static let reminderCategoryId = "com.ichigo.AlgoApp.reminders"
    
    private static let reminderIdKey = "reminderId"
    
    static func setupNotificationSettings() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // TODO: update UI if not granted or encounter error
        }
        
        let openProblemAction = UNNotificationAction(
            identifier: openProblemActionId,
            title: "Solve Problem",
            options: .foreground
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: reminderCategoryId,
            actions: [openProblemAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([reminderCategory])
    }
    
    static func updateScheduledNotifications(for reminder: ReminderDetail) {
        cancelAllScheduledNotifications(for: reminder)
        guard reminder.enabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to practice coding again!"
        content.body = "A coding problem is waiting for you to solve 👩‍💻"
        content.categoryIdentifier = reminderCategoryId
        content.userInfo[reminderIdKey] = reminder.id
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let minuteComponent = calendar.component(.minute, from: reminder.date)
        let hourComponent = calendar.component(.hour, from: reminder.date)
        
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.hour = hourComponent
        dateComponents.minute = minuteComponent
        
        let repeats = !reminder.repeatDays.isEmpty
        for weekday in reminder.repeatDays {
            dateComponents.weekday = weekday
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
    
    static func cancelAllScheduledNotifications(for reminder: ReminderDetail) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            var foundRequestIds: [String] = []
            for request in requests {
                guard let reminderId = request.content.userInfo[reminderIdKey] as? String,
                    reminderId == reminder.id else { continue }
                foundRequestIds.append(request.identifier)
            }
            
            center.removePendingNotificationRequests(withIdentifiers: foundRequestIds)
        }
    }
}
