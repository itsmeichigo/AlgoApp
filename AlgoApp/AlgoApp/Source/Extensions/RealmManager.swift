//
//  RealmManager.swift
//  AlgoApp
//
//  Created by Huong Do on 5/23/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RealmSwift
import RxRealm
import RxSwift
import RxCocoa

final class RealmManager {
    
    static let shared = RealmManager(configuration: Realm.Configuration.defaultConfiguration)
    
    public let realmForRead: Realm
    public let realmForWrite: Realm
    
    init(configuration: Realm.Configuration) {
        do {
            self.realmForRead = try Realm(configuration: configuration)
            self.realmForWrite = try Realm(configuration: configuration)
        } catch let error {
            fatalError(String(describing: error))
        }
    }
    
    func object<T: Object>(_ type: T.Type, id: T.Identity) -> T? where T: IdentifiableObject {
        return realmForRead.object(ofType: type, forPrimaryKey: id)
    }
    
    func object<T: Object>(_ type: T.Type, filter predicate: NSPredicate) -> T? {
        return realmForRead.objects(type).filter(predicate).first
    }
    
    // return observable from realm object if existed, if not, just return empty observable
    
    func observableExistedObject<T: Object>(_ type: T.Type, id: T.Identity) -> Observable<T> where T: IdentifiableObject {
        guard let object = realmForRead.object(ofType: type, forPrimaryKey: id) else {
            return Observable.empty()
        }
        return Observable<T>.from(object: object)
        
    }
    
    // wait until find the realm object then return observable from it
    
    func observableObject<T: Object>(_ type: T.Type, id: T.Identity) -> Observable<T> where T: IdentifiableObject {
        return observableObjects(type)
            .map { $0.first(where: { $0.id == id }) }
            .filterNil()
    }
    
    func objects<T: Object>(_ type: T.Type) -> Results<T> {
        return realmForRead.objects(type)
    }
    
    func objects<T: Object>(_ type: T.Type, filter predicate: NSPredicate) -> Results<T> {
        return realmForRead.objects(type).filter(predicate)
    }
    
    func observableObjects<T: Object>(_ type: T.Type) -> Observable<Results<T>> {
        return Observable.collection(from: realmForRead.objects(type))
    }
    
    func observableObjects<T: Object>(_ type: T.Type, filter predicate: NSPredicate) -> Observable<Results<T>> {
        return Observable.collection(from: realmForRead.objects(type).filter(predicate))
    }
    
    func create(object: Object, update: Bool = false) {
        tryOrLogError { $0.add(object, update: update ? .modified : .error) }
    }
    
    func create(objects: [Object], update: Bool = false) {
        tryOrLogError { $0.add(objects, update: update ? .modified : .error) }
    }
    
    func create<T: Object>(_ type: T.Type, value: Any, update: Bool = false) {
        tryOrLogError { $0.create(type, value: value, update: update ? .modified : .error) }
    }
    
    func delete<T: RealmSwift.Object>(object: T) {
        tryOrLogError { $0.delete(object) }
    }
    
    func delete<T: Object>(objects: RealmSwift.Results<T>) {
        tryOrLogError { $0.delete(objects) }
    }
    
    func delete<T: Object>(list objects: RealmSwift.List<T>) {
        tryOrLogError { $0.delete(objects) }
    }
    
    func clearData() {
        tryOrLogError { $0.deleteAll() }
    }
    
    func update(block: @escaping () -> Void) {
        tryOrLogError { _ in block() }
    }
    
    private func tryOrLogError(_ block: ((_ realm: Realm) throws -> Void)) {
        do {
            if realmForWrite.isInWriteTransaction {
                try block(realmForWrite)
            } else {
                try realmForWrite.write {
                    try block(realmForWrite)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

public protocol IdentifiableObject {
    associatedtype Identity: Hashable
    var id: Identity { get set }
}
