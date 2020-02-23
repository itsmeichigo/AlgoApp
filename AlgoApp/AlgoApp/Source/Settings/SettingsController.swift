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
import CloudKit

class SettingsController: UITableViewController {
    
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    @IBOutlet var arrowImageViews: [UIImageView]!
    @IBOutlet var titleLabels: [UILabel]!
    @IBOutlet var cardViews: [UIView]!
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet weak var iCloudStatusLabel: UILabel!
    @IBOutlet weak var sortOptionLabel: UILabel!
    
    @IBOutlet weak var iCloudButton: UIButton!
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
            contactButton,
            iCloudButton
        ]
    }
    
    private let disposeBag = DisposeBag()
    private let iCloudEnabled = PublishRelay<Bool>()
    
    private let viewWillAppearSignal = PublishRelay<Void>()
    private let didBecomeActiveSignal = UIApplication.shared
            .rx.applicationDidBecomeActive
            .startWith(.active)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateColors()
        configureView()
        configureNavigationBar()
        
        AppConfigs.shared.currentThemeDriver
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
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appPurpleColor()
        viewWillAppearSignal.accept(())
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppConfigs.shared.currentTheme == .light ? .default : .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        
        tableView.tableFooterView = UIView()
        
        darkModeSwitch.isOn = AppConfigs.shared.currentTheme == .dark
        
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
                AppConfigs.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewWillAppearSignal, didBecomeActiveSignal)
            .flatMapLatest { [weak self] _ in self?.checkiCloudStatus() ?? .just(false) }
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] in
                self?.iCloudStatusLabel.text = $0 == true ? "On" : "Off"
            })
            .bind(to: iCloudEnabled)
            .disposed(by: disposeBag)
        
        iCloudButton.rx.tap
            .withLatestFrom(iCloudEnabled)
            .subscribe(onNext: { [weak self] in
                self?.showiCloudDetail(isEnabled: $0)
            })
            .disposed(by: disposeBag)
        
        goPremiumButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in self.showPremiumDetail() })
            .disposed(by: disposeBag)
        
        contactButton.rx.tap.asDriver()
            .drive(onNext: {
                guard let url = URL(string: AppConstants.twitterPath),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            .disposed(by: disposeBag)
        
        reviewButton.rx.tap.asDriver()
            .drive(onNext: {
                guard let url = URL(string: AppConstants.appStorePath),
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
        
        tabBarController?.tabBar.barTintColor = AppConfigs.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
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
        
        tableView.reloadData()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func showSortOptions() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "SortOptionsViewController") as? SortOptionsViewController else { return }
        
        presentPanModal(controller, sourceView: sortOptionLabel, sourceRect: CGRect(x: sortOptionLabel.frame.width / 2, y: sortOptionLabel.frame.height, width: 0, height: 0))
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }

    private func showPremiumAlert() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "FeatureDetailViewController") as? FeatureDetailViewController else { return }
        
        controller.mode = .darkMode
        controller.dismissHandler = { [weak self] in
            self?.showPremiumDetail()
        }
        presentPanModal(controller, sourceView: darkModeSwitch, sourceRect: CGRect(x: darkModeSwitch.frame.width / 2, y: darkModeSwitch.frame.height, width: 0, height: 0))
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }
    
    private func checkiCloudStatus() -> Observable<Bool> {
        return Observable<Bool>.create { observer in
            CKContainer.default().accountStatus { (status, error) in
                if (status == .available) {
                    observer.onNext(true)
                } else {
                    observer.onNext(false)
                }
            }
            
            return Disposables.create {}
        }
    }
    
    private func showiCloudDetail(isEnabled: Bool) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "FeatureDetailViewController") as? FeatureDetailViewController else { return }
        
        controller.mode = .iCloud(isEnabled: isEnabled)
        presentPanModal(controller, sourceView: iCloudButton, sourceRect: CGRect(x: iCloudButton.frame.width, y: iCloudButton.frame.height / 2, width: 0, height: 0))
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }
    
    private func showPremiumDetail() {
        guard let detailController = storyboard?.instantiateViewController(withIdentifier: "PremiumDetailNavigationController") else { return }
        present(detailController, animated: true, completion: nil)
    }
}

extension SettingsController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.row {
        case 0:
            // hide theme switch in iOS 13
            if #available(iOS 13.0, *) {
                return 0
            } else {
               return AppHelper.isIpad ? 126 : 84
            }

        case 1: return AppHelper.isIpad ? 156 : 136
        case 2: return AppConfigs.shared.isPremium ? 0 : (AppHelper.isIpad ? 86 : 76)
        case 3: return AppHelper.isIpad ? 234 : 204
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.backgroundColor = .backgroundColor()
    }
}
