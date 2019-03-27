//
//  SettingsController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import PanModal
import UIKit
import RxCocoa
import RxSwift

class SettingsController: UITableViewController {
    
    @IBOutlet weak var hidesSolvedSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    @IBOutlet var arrowImageViews: [UIImageView]!
    @IBOutlet var titleLabels: [UILabel]!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var cardViews: [UIView]!
    @IBOutlet var separatorViews: [UIView]!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateColors()
        configureView()
        configureNavigationBar()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.darkModeSwitch.isOn = theme == .dark
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.tintColor = .appPurpleColor()
        super.viewWillAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        darkModeSwitch.isOn = Themer.shared.currentTheme == .dark
        hidesSolvedSwitch.isOn = AppConfigs.shared.hidesSolvedProblems
        
        cardViews.forEach { view in
            view.layer.cornerRadius = 8.0
            view.dropCardShadow()
        }
        
        darkModeSwitch.rx.isOn.asDriver()
            .withLatestFrom(AppConfigs.shared.isPremiumDriver) { ($0, $1) }
            .map { !$0.1 ? Theme.light : $0.0 ? Theme.dark : Theme.light }
            .drive(onNext: {
                Themer.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
        
        darkModeSwitch.rx.isOn.asDriver()
            .withLatestFrom(AppConfigs.shared.isPremiumDriver) { ($0, $1) }
            .skip(1)
            .drive(onNext: { [weak self] in
                if !$0.1, self?.presentedViewController == nil {
                    self?.showPremiumAlert()
                }
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
        
        tabBarController?.tabBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
        hidesSolvedSwitch.onTintColor = .secondaryColor()
        darkModeSwitch.onTintColor = .secondaryColor()
        
        titleLabels.forEach { label in
            label.textColor = .titleTextColor()
        }
        
        buttons.forEach { button in
            button.tintColor = .titleTextColor()
        }
        
        cardViews.forEach { view in
            view.backgroundColor = .primaryColor()
        }
        
        arrowImageViews.forEach { imageView in
            imageView.tintColor = .subtitleTextColor()
        }
        
        separatorViews.forEach { view in
            view.backgroundColor = .borderColor()
        }
        
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }

    private func showPremiumAlert() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "PremiumAlertViewController") as? PremiumAlertViewController,
            let detailController = storyboard?.instantiateViewController(withIdentifier: "PremiumDetailNavigationController") else { return }
        
        controller.mode = .darkMode
        controller.dismissHandler = { [weak self] in
            self?.present(detailController, animated: true, completion: nil)
        }
        presentPanModal(controller)
    }
}
