//
//  NotesViewModel.swift
//  AlgoApp
//
//  Created by Huong Do on 4/7/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxRealm
import RealmSwift

final class NotesViewModel {
    let notes = BehaviorRelay<[NoteCellModel]>(value: [])
    
    private let disposeBag = DisposeBag()
    private lazy var realm = try! Realm()
    
    func loadNotes() {
        Observable.collection(from: realm.objects(Note.self))
            .map { Array($0)
                    .map { NoteCellModel(with: $0) }
                    .sorted(by: { $0.lastUpdated > $1.lastUpdated })
            }
            .bind(to: notes)
            .disposed(by: disposeBag)
    }
    
    func deleteNote(_ note: NoteCellModel) {
        guard let model = realm.object(ofType: Note.self, forPrimaryKey: note.id),
            let question = realm.object(ofType: Question.self, forPrimaryKey: note.questionId) else { return }
        try! realm.write {
            realm.delete(model)
            question.note = nil
        }
    }
}
