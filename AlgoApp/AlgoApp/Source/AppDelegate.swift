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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let disposeBag = DisposeBag()
    
    /// set orientations you want to be allowed in this property by default
    var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        configureRealm()
        StoreHelper.checkPendingTransactions()
        
        setupRootController()
        
        NotificationHelper.shared.showPendingQuestion()
        
        return true
    }

    private func configureRealm() {
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
        
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!
        let bundleReamPath = Bundle.main.path(forResource: "default", ofType:"realm")
        
        guard !FileManager.default.fileExists(atPath: defaultRealmPath.path) else { return }
        
        do {
            try FileManager.default.copyItem(atPath: bundleReamPath!, toPath: defaultRealmPath.path)
        } catch let error as NSError {
            print("error occurred, here are the details:\n \(error)")
        }
    }
    
    private func setupRootController() {
        let tabbarController = UITabBarController(nibName: nil, bundle: nil)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabbarController
        window?.makeKeyAndVisible()
        
        guard let homeController = StoryboardHelper.homeStoryboard().instantiateInitialViewController(),
            let remindersController = StoryboardHelper.remindersStoryboard().instantiateInitialViewController(),
            let notesController = StoryboardHelper.notesStoryboard().instantiateInitialViewController(),
            let settingsController = StoryboardHelper.settingsStoryboard().instantiateInitialViewController() else { return }
        
        homeController.tabBarItem.image = UIImage(named: "cat")
        remindersController.tabBarItem.image = UIImage(named: "reminder")
        notesController.tabBarItem.image = UIImage(named: "notes")
        settingsController.tabBarItem.image = UIImage(named: "settings")
        
        let controllers = [homeController, remindersController, notesController, settingsController]
        controllers.forEach { controllers in
            controllers.tabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        }

        tabbarController.viewControllers = controllers
    }
}

enum StoryboardHelper {
    static func homeStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Home", bundle: nil)
    }
    
    static func remindersStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Reminders", bundle: nil)
    }
    
    static func notesStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Notes", bundle: nil)
    }
    
    static func settingsStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Settings", bundle: nil)
    }
}
