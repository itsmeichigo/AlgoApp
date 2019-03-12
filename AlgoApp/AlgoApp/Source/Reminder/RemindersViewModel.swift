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
    private lazy var realm: Realm = {
        let config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 4) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        Realm.Configuration.defaultConfiguration = config
        
        return try! Realm()
    }()
    
    func loadReminders() {
        Observable.collection(from: realm.objects(Reminder.self))
            .map { Array($0).map { ReminderDetail(with: $0) } }
            .bind(to: reminders)
            .disposed(by: disposeBag)
    }
}
