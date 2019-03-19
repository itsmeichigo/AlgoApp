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
    
    @IBOutlet weak var hidesSolvedSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    @IBOutlet var titleLabels: [UILabel]!
    @IBOutlet var cardViews: [UIView]!
    @IBOutlet var separatorViews: [UIView]!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureNavigationBar()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
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
        
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        
        darkModeSwitch.isOn = Themer.shared.currentTheme == .dark
        hidesSolvedSwitch.isOn = AppConfigs.shared.hidesSolvedProblems
        
        cardViews.forEach { view in
            view.layer.cornerRadius = 8.0
            view.dropCardShadow()
        }
        
        darkModeSwitch.rx.isOn
            .map { $0 ? Theme.dark : Theme.light }
            .subscribe(onNext: {
                Themer.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
        
        hidesSolvedSwitch.rx.isOn
            .subscribe(onNext: {
                AppConfigs.shared.hidesSolvedProblems = $0
            })
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.tintColor = .secondaryColor()
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        hidesSolvedSwitch.onTintColor = .secondaryColor()
        darkModeSwitch.onTintColor = .secondaryColor()
        
        titleLabels.forEach { label in
            label.textColor = .titleTextColor()
        }
        
        cardViews.forEach { view in
            view.backgroundColor = .primaryColor()
        }
        
        separatorViews.forEach { view in
            view.backgroundColor = .borderColor()
        }
        
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }

}
