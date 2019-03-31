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
    @IBOutlet var cardViews: [UIView]!
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet weak var sortOptionLabel: UILabel!
    
    @IBOutlet weak var sortProblemsButton: UIButton!
    @IBOutlet weak var goPremiumButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    
    private var buttons: [UIButton] {
        return [
            sortProblemsButton,
            goPremiumButton,
            aboutButton,
            reviewButton,
            contactButton
        ]
    }
    
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
        
        AppConfigs.shared.isPremiumDriver
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        AppConfigs.shared.sortOptionDriver
            .map { $0.displayText }
            .drive(sortOptionLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.tintColor = .appPurpleColor()
        tableView.reloadData()
        super.viewWillAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        
        tableView.tableFooterView = UIView()
        
        darkModeSwitch.isOn = Themer.shared.currentTheme == .dark
        hidesSolvedSwitch.isOn = AppConfigs.shared.hidesSolvedProblems
        
        cardViews.forEach { view in
            view.layer.cornerRadius = 8.0
            view.dropCardShadow()
        }
        
        darkModeSwitch.rx.isOn.asDriver()
            .withLatestFrom(AppConfigs.shared.isPremiumDriver) { ($0, $1) }
            .skip(1)
            .do(onNext: { [weak self] in
                if !$0.1, self?.presentedViewController == nil {
                    self?.showPremiumAlert()
                }
            })
            .map { !$0.1 ? Theme.light : $0.0 ? Theme.dark : Theme.light }
            .drive(onNext: {
                Themer.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
        
        hidesSolvedSwitch.rx.isOn
            .subscribe(onNext: {
                AppConfigs.shared.hidesSolvedProblems = $0
            })
            .disposed(by: disposeBag)
        
        goPremiumButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in self.showPremiumDetail() })
            .disposed(by: disposeBag)
        
        contactButton.rx.tap.asDriver()
            .drive(onNext: {
                let path = "https://twitter.com/itsmeichigo"
                guard let url = URL(string: path),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap.asDriver()
            .drive(onNext: {
                let path = "itms-apps://itunes.apple.com/app/id1457038505"
                guard let url = URL(string: path),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            .disposed(by: disposeBag)
        
        sortProblemsButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in self.showSortOptions() })
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
        hidesSolvedSwitch.onTintColor = .secondaryColor()
        darkModeSwitch.onTintColor = .secondaryColor()
        
        sortOptionLabel.textColor = .subtitleTextColor()
        
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
    
    private func showSortOptions() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "SortOptionsViewController") as? SortOptionsViewController else { return }
        presentPanModal(controller)
    }

    private func showPremiumAlert() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "PremiumAlertViewController") as? PremiumAlertViewController else { return }
        
        controller.mode = .darkMode
        controller.dismissHandler = { [weak self] in
            self?.showPremiumDetail()
        }
        presentPanModal(controller)
    }
    
    private func showPremiumDetail() {
        guard let detailController = storyboard?.instantiateViewController(withIdentifier: "PremiumDetailNavigationController") else { return }
        present(detailController, animated: true, completion: nil)
    }
}

extension SettingsController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.row {
        case 0: return 84
        case 1: return 136
        case 2: return AppConfigs.shared.isPremium ? 0 : 76
        case 3: return 204
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
}
