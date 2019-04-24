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
        AppConfigs.shared.isPremium = true
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
