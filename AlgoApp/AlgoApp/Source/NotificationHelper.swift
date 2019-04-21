//
//  Scheduler.swift
//  AlgoApp
//
//  Created by Huong Do on 3/17/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxSwift
import UIKit
import UserNotifications

final class NotificationHelper: NSObject {
    
    static let shared = NotificationHelper()
    let center = UNUserNotificationCenter.current()
    
    private static let openProblemActionId = "com.ichigo.AlgoApp.reminders.problem"
    private static let reminderCategoryId = "com.ichigo.AlgoApp.reminders"
    
    private static let reminderIdKey = "reminderId"
    
    private var pendingReminderId: String?
    
    private let reminderTitles: [String] = [
        "Time to practice coding again!",
        "What time is it? Puzzle time!",
        "You asked to be reminded - you got it!",
        "Yet another reminder to practice coding",
        "Ready? Puzzle time!"
    ]
    
    private let reminderBodies: [String] = [
        "A coding challenge is waiting for you to solve 👩‍💻",
        "Keep your coding skills sharp with at least one challenge a day 🤓",
        "You're doing better everyday 🥳 Here's another coding challenge for you.",
        "You're guaranteed to learn something new 🤯 by trying this coding problem.",
        "Be a ninja and take on this one challenge picked especially for you 😏"
    ]
    
    override init() {
        super.init()
        setupNotificationSettings()
    }
    
    func setupNotificationSettings() {
        
        let openProblemAction = UNNotificationAction(
            identifier: NotificationHelper.openProblemActionId,
            title: "Solve Problem",
            options: .foreground
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationHelper.reminderCategoryId,
            actions: [openProblemAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        center.setNotificationCategories([reminderCategory])
        center.delegate = self
    }
    
    func updateScheduledNotifications(for reminder: ReminderDetail) {
        cancelScheduledNotifications(for: reminder) { [weak self] in
            guard reminder.enabled else { return }
            
            let content = UNMutableNotificationContent()
            content.title = self?.reminderTitles.randomElement() ?? ""
            content.body = self?.reminderBodies.randomElement() ?? ""
            content.categoryIdentifier = NotificationHelper.reminderCategoryId
            content.userInfo[NotificationHelper.reminderIdKey] = reminder.id
            
            let calendar = Calendar.current
            let minuteComponent = calendar.component(.minute, from: reminder.date)
            let hourComponent = calendar.component(.hour, from: reminder.date)
            
            var dateComponents = DateComponents()
            dateComponents.calendar = calendar
            dateComponents.hour = hourComponent
            dateComponents.minute = minuteComponent
            
            if reminder.repeatDays.isEmpty {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                self?.center.add(request, withCompletionHandler: nil)
            } else {
                for weekday in reminder.repeatDays {
                    dateComponents.weekday = weekday
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    self?.center.add(request, withCompletionHandler: nil)
                }
            }
        }
    }
    
    func showPendingQuestion() {
        guard let id = pendingReminderId else { return }
        
        guard let window = UIApplication.shared.keyWindow,
            let tabbarController = window.rootViewController as? UITabBarController,
            let navigationController = tabbarController.viewControllers?.first as? UINavigationController else {
                
            return
        }
        
        if let presentedController = navigationController.topViewController?.presentedViewController {
            presentedController.dismiss(animated: false, completion: nil)
        }
        
        navigationController.popToRootViewController(animated: false)
        
        let storyboard = AppHelper.homeStoryboard
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController,
            let questionId = Reminder.randomQuestionId(for: id) else { return }
        
        viewController.viewModel = DetailViewModel(question: questionId)
        navigationController.pushViewController(viewController, animated: true)
        
        tabbarController.selectedIndex = 0
    }
    
    func cancelScheduledNotifications(for reminder: ReminderDetail, completionHandler: @escaping (() -> Void)) {
        
        center.getPendingNotificationRequests { [weak self] requests in
            var foundRequestIds: [String] = []
            for request in requests {
                guard let reminderId = request.content.userInfo[NotificationHelper.reminderIdKey] as? String,
                    reminderId == reminder.id else { continue }
                foundRequestIds.append(request.identifier)
            }
            
            self?.center.removePendingNotificationRequests(withIdentifiers: foundRequestIds)
            completionHandler()
        }
    }
    
    func cancelAllScheduledNotifications() {
        center.removeAllPendingNotificationRequests()
        Reminder.disableAllReminders()
    }
}

extension NotificationHelper: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        completionHandler()
        
        if let reminderId = response.notification.request.content.userInfo[NotificationHelper.reminderIdKey] as? String {
            
            guard let window = UIApplication.shared.keyWindow,
                let tabbarController = window.rootViewController as? UITabBarController,
                let navigationController = tabbarController.viewControllers?.first as? UINavigationController else {
                    
                self.pendingReminderId = reminderId
                return
            }
            
            if let presentedController = navigationController.topViewController?.presentedViewController {
                presentedController.dismiss(animated: false, completion: nil)
            }
            
            navigationController.popToRootViewController(animated: false)
            
            let storyboard = AppHelper.homeStoryboard
            guard let viewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController,
                let questionId = Reminder.randomQuestionId(for: reminderId) else { return }
            
            viewController.viewModel = DetailViewModel(question: questionId)
            navigationController.pushViewController(viewController, animated: true)
            
            tabbarController.selectedIndex = 0
            
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
}

extension Reactive where Base: UNUserNotificationCenter {
    
    public func requestAuthorization(options: UNAuthorizationOptions = []) -> Single<Bool> {
        return Single.create(subscribe: { (event) -> Disposable in
            self.base.requestAuthorization(options: options) { (success: Bool, error: Error?) in
                if let error = error {
                    event(.error(error))
                } else {
                    event(.success(success))
                }
            }
            return Disposables.create()
        })
    }
}

