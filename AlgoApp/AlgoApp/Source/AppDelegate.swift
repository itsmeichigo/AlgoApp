//
//  AppDelegate.swift
//  AlgoApp
//
//  Created by Huong Do on 2/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift
import RxSwift
import RxCocoa
import CloudKit
import IceCream

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var syncEngine: SyncEngine?
    
    private let disposeBag = DisposeBag()
    
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        configureRealm()
        
        syncEngine = SyncEngine(objects: [
            SyncObject<QuestionList>(),
            SyncObject<Note>(),
            SyncObject<Reminder>()
            ])
        
        StoreHelper.checkPendingTransactions()
        
        setupRootController()
        
        application.registerForRemoteNotifications()
        NotificationHelper.shared.showPendingQuestion()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let dict = userInfo as! [String: NSObject]
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)
        
        if let subscriptionID = notification?.subscriptionID, IceCreamSubscription.allIDs.contains(subscriptionID) {
            NotificationCenter.default.post(name: Notifications.cloudKitDataDidChangeRemotely.name, object: nil, userInfo: userInfo)
        }
        completionHandler(.newData)
        
    }
}

private extension AppDelegate {
    func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 6,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 6) {
                    migration.enumerateObjects(ofType: "Solution", { (oldObject, newObject) in
                        newObject?["id"] = UUID().uuidString
                    })
                }
        })
        Realm.Configuration.defaultConfiguration = config
        
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
        let bundleReamPath = Bundle.main.path(forResource: "default", ofType:"realm")
        
        guard !FileManager.default.fileExists(atPath: defaultRealmPath.path) else { return }
        
        do {
            try FileManager.default.copyItem(atPath: bundleReamPath!, toPath: defaultRealmPath.path)
            QuestionList.createCustomListsIfNeeded()
        } catch let error as NSError {
            print("error occurred, here are the details:\n \(error)")
        }
    }
    
    func setupRootController() {
        let tabbarController = UITabBarController(nibName: nil, bundle: nil)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabbarController
        window?.makeKeyAndVisible()
        
        guard let homeController = AppHelper.homeStoryboard.instantiateInitialViewController(),
            let remindersController = AppHelper.remindersStoryboard.instantiateInitialViewController(),
            let notesController = AppHelper.notesStoryboard.instantiateInitialViewController(),
            let settingsController = AppHelper.settingsStoryboard.instantiateInitialViewController() else { return }
        
        let images: [UIImage?] = [UIImage(named: "cat"), UIImage(named: "reminder"), UIImage(named: "notes"), UIImage(named: "settings")]
        let names = ["Challenges", "Reminders", "Notes", "Settings"]
        let controllers = [homeController, remindersController, notesController, settingsController]
        for (index, controller) in controllers.enumerated() {
            controller.tabBarItem.image = images[index]
            controller.tabBarItem.title = AppHelper.isIpad ? names[index] : ""
            
            let offset: CGFloat = AppHelper.isIpad ? 0 : 6
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
        }
        
        tabbarController.viewControllers = controllers
    }
}
