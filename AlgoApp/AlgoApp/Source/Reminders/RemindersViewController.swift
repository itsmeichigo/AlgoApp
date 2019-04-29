//
//  ReminderViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/7/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxDataSources
import RxSwift

class RemindersViewController: UIViewController {

    typealias ReminderSection = SectionModel<String, ReminderDetail>
    typealias Datasource = RxCollectionViewSectionedReloadDataSource<ReminderSection>
    
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet private weak var emptyImageView: UIImageView!
    @IBOutlet private weak var emptyTitleLabel: UILabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let disposeBag = DisposeBag()
    private let viewModel = RemindersViewModel()
    
    private var premiumViewController: PremiumAlertViewController?
    
    private lazy var datasource: Datasource = buildDatasource()
    
    private lazy var addButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureNavigationBar()
        updateColors()
        
        viewModel.loadReminders()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appYellowColor()
        viewModel.disableExpiredReminders()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard viewIfLoaded?.window != nil else { return }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        
        addButton.setImage(UIImage(named: "plus"), for: .normal)
        addButton.addTarget(self, action: #selector(addNewReminder), for: .touchUpInside)
        addButton.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        
        let addBarButton = UIBarButtonItem(customView: addButton)
        navigationItem.rightBarButtonItem = addBarButton
    }
    
    private func configureView() {
        
        collectionView.delegate = self
        
        openSettingsButton.layer.cornerRadius = openSettingsButton.frame.height / 2
        openSettingsButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.openSettings() })
            .disposed(by: disposeBag)
        
        let notificationGranted = UIApplication.shared.rx.applicationDidBecomeActive
            .startWith(.active)
            .withLatestFrom(AppConfigs.shared.isPremiumDriver)
            .filter { $0 }
            .flatMap { _ in NotificationHelper.shared.center
                .rx.requestAuthorization(options: [.alert, .sound]) }
            .map { $0 }
            .asDriver(onErrorJustReturn: false)
            .startWith(true)
        
        notificationGranted
            .map { $0 ? UIImage(named: "notification") : UIImage(named: "permission") }
            .drive(emptyImageView.rx.image)
            .disposed(by: disposeBag)
        
        notificationGranted
            .map { $0 ? "No reminders yet" : "Push notification disabled" }
            .drive(emptyTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        notificationGranted
            .map { $0 ? "Keep your coding skills sharp \nwith daily challenges" : "Please enable notification settings \nto receive reminders with coding problems" }
            .drive(emptyMessageLabel.rx.text)
            .disposed(by: disposeBag)
        
        notificationGranted
            .map { !$0 }
            .drive(collectionView.rx.isHidden)
            .disposed(by: disposeBag)
        
        notificationGranted
            .map { $0 }
            .drive(openSettingsButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.reminders.asDriver()
            .map { [ReminderSection(model: "", items: $0)] }
            .drive(collectionView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        Driver.combineLatest(viewModel.reminders.asDriver(), notificationGranted)
            .map { !$0.0.isEmpty && $0.1 }
            .drive(emptyStackView.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .backgroundColor()
        collectionView.backgroundColor = .backgroundColor()
        premiumViewController?.updateColors()
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
        
        openSettingsButton.setTitleColor(.white, for: .normal)
        openSettingsButton.backgroundColor = UIColor.appPurpleColor()
        
        addButton.tintColor = .secondaryColor()
        
        collectionView.reloadData()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func configureCollectionViewLayoutItemSize(for width: CGFloat) -> CGSize {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let buffer: CGFloat = AppHelper.isIpad ? 32 : 0
        let inset = UIEdgeInsets(top: 8 + buffer, left: 0 + buffer, bottom: 8 + buffer, right: 0 + buffer)
        layout.sectionInset = inset
        
        let cellHeight: CGFloat = 141
        if isRegularWidth {
            let spacing = layout.minimumInteritemSpacing
            return CGSize(width: (width - inset.left - inset.right - spacing) / 3, height: cellHeight)
        } else {
            return CGSize(width: width, height: cellHeight)
        }
    }

    private func buildDatasource() -> Datasource {
        return RxCollectionViewSectionedReloadDataSource<ReminderSection>(configureCell: { (_, collectionView, indexPath, model) -> UICollectionViewCell in
            let cell: ReminderCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configureCell(model: model)
            cell.enabledSwitch.rx.controlEvent(UIControl.Event.valueChanged)
                .subscribe(onNext: { [weak self] in
                    self?.viewModel.toggleReminder(id: model.id)
                })
                .disposed(by: cell.disposeBag)
            return cell
        })
    }
    
    @objc private func addNewReminder() {
        if AppHelper.isIpad && !AppConfigs.shared.isPremium {
            showPremiumAlert()
        } else {
            showDetail(model: nil, sourceView: addButton, sourceRect: CGRect(x: addButton.frame.width / 2, y: addButton.frame.height, width: 0, height: 0))
        }
    }
    
    private func showDetail(model: ReminderDetail?, sourceView: UIView? = nil, sourceRect: CGRect = .zero) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "ReminderNavigationController") as? UINavigationController,
            let controller = navigationController.topViewController as? ReminderDetailViewController else { return }
        let viewModel = ReminderDetailViewModel(reminder: model)
        controller.viewModel = viewModel
        
        if AppHelper.isIpad {
            navigationController.modalPresentationStyle = .popover
            navigationController.popoverPresentationController?.sourceRect = sourceRect
            navigationController.popoverPresentationController?.sourceView = sourceView
        }
        
        present(navigationController, animated: true, completion: nil)
        
        navigationController.popoverPresentationController?.backgroundColor = UIColor.backgroundColor()
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
    }
    
    private func showPremiumAlert() {
        guard let controller = AppHelper.settingsStoryboard.instantiateViewController(withIdentifier: "PremiumAlertViewController") as? PremiumAlertViewController else { return }
        
        controller.mode = .alarm
        controller.dismissHandler = { [weak self] in
            self?.showPremiumDetail()
        }
        presentPanModal(controller, sourceView: addButton, sourceRect: CGRect(x: addButton.frame.width / 2, y: addButton.frame.height, width: 0, height: 0))
    }
    
    private func showPremiumDetail() {
        let detailController = AppHelper.settingsStoryboard.instantiateViewController(withIdentifier: "PremiumDetailNavigationController")
        present(detailController, animated: true, completion: nil)
    }
}

extension RemindersViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ReminderCell {
            cell.cardView.backgroundColor = .selectedBackgroundColor()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ReminderCell {
            cell.cardView.backgroundColor = .primaryColor()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.reminders.value[indexPath.item]
        if let cell = collectionView.cellForItem(at: indexPath) {
            showDetail(model: item, sourceView: cell, sourceRect: CGRect(x: cell.frame.width / 2, y: cell.frame.height / 2, width: 0, height: 0))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin = view.safeAreaInsets.left + view.safeAreaInsets.right
        let width = UIScreen.main.bounds.width - margin
        return configureCollectionViewLayoutItemSize(for: width)
    }
}
