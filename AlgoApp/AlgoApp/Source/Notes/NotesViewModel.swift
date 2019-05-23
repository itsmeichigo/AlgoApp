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
    private lazy var realmManager = RealmManager.shared
    
    func loadNotes() {
        realmManager.observableObjects(Note.self, filter: NSPredicate(format: "isDeleted = false"))
            .do(onNext: { [weak self] notes in
                guard let self = self else { return }
                
                self.realmManager.update {
                    for note in notes {
                        if let question = self.realmManager.object(Question.self, id: note.questionId), question.note == nil {
                            question.note = note
                        }
                    }
                }
            })
            .map { Array($0)
                    .map { NoteCellModel(with: $0) }
                    .sorted(by: { $0.lastUpdated > $1.lastUpdated })
            }
            .bind(to: notes)
            .disposed(by: disposeBag)
    }
    
    func deleteNote(_ note: NoteCellModel) {
        guard let model = realmManager.object(Note.self, id: note.id),
            let question = realmManager.object(Question.self, id: note.questionId) else { return }
        
        realmManager.update {
            model.isDeleted = true
            question.note = nil
        }
    }
}
