//
//  SettingsController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsController: UITableViewController {
    
    @IBOutlet weak var showsUnreadSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    @IBOutlet var titleLabels: [UILabel]!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureNavigationBar()
        
        Themer.shared.currentThemeRelay
            .subscribe(onNext: { [weak self] theme in
                self?.darkModeSwitch.isOn = theme == .dark
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        updateColors()
        
        tableView.tableFooterView = UIView()
        darkModeSwitch.isOn = Themer.shared.currentTheme == .dark
        
        darkModeSwitch.rx.isOn
            .map { $0 ? Theme.dark : Theme.light }
            .subscribe(onNext: {
                Themer.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.tintColor = .secondaryYellowColor()
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        showsUnreadSwitch.onTintColor = .secondaryYellowColor()
        darkModeSwitch.onTintColor = .secondaryYellowColor()
        
        titleLabels.forEach({ label in
            label.textColor = .titleTextColor()
        })
        
        tableView.separatorColor = .borderColor()
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }

}
