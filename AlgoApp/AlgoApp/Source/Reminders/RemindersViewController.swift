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
    typealias Datasource = RxTableViewSectionedReloadDataSource<ReminderSection>
    
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet private weak var emptyImageView: UIImageView!
    @IBOutlet private weak var emptyTitleLabel: UILabel!
    @IBOutlet private weak var emptyMessageLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    @IBOutlet private weak var addButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    private let viewModel = RemindersViewModel()
    
    private var premiumViewController: PremiumAlertViewController?
    
    private lazy var datasource: Datasource = buildDatasource()
    
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
        tabBarController?.tabBar.tintColor = .secondaryColor()
        super.viewWillAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "addNewReminder",
            let destination = segue.destination as? UINavigationController,
            let controller = destination.topViewController as? ReminderDetailViewController {
            let viewModel = ReminderDetailViewModel(reminder: nil)
            controller.viewModel = viewModel
        }
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PremiumAlertViewController") as? PremiumAlertViewController,
            let premiumView = controller.view {
            
            view.addSubview(premiumView)
            premiumView.snp.makeConstraints { maker in
                maker.bottom.leading.trailing.equalToSuperview()
                maker.top.equalToSuperview().offset(-20)
            }
            
            premiumViewController = controller
            
            if let detailController = storyboard?.instantiateViewController(withIdentifier: "PremiumDetailNavigationController") {
                controller.dismissHandler = { [weak self] in
                    self?.present(detailController, animated: true, completion: nil)
                }
            }
            
            AppConfigs.shared.isPremiumDriver
                .drive(premiumView.rx.isHidden)
                .disposed(by: disposeBag)
        }
        
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 36, right: 0)
        
        openSettingsButton.layer.cornerRadius = openSettingsButton.frame.height / 2
        openSettingsButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.openSettings() })
            .disposed(by: disposeBag)
        
        let notificationGranted = UIApplication.shared.rx.applicationDidBecomeActive
            .startWith(.active)
            .flatMap { _ in NotificationHelper.shared.center
                .rx.requestAuthorization(options: [.alert, .sound]) }
            .map { $0 }
            .asDriver(onErrorJustReturn: false)
        
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
            .drive(tableView.rx.isHidden)
            .disposed(by: disposeBag)
        
        notificationGranted
            .map { $0 }
            .drive(openSettingsButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.reminders.asDriver()
            .map { [ReminderSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        Driver.combineLatest(viewModel.reminders.asDriver(), notificationGranted)
            .map { !$0.0.isEmpty && $0.1 }
            .drive(emptyStackView.rx.isHidden)
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(ReminderDetail.self)
            .subscribe(onNext: { [unowned self] in
                self.showDetail(model: $0)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .backgroundColor()
        premiumViewController?.updateColors()
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
        addButton.tintColor = .secondaryColor()
        
        openSettingsButton.setTitleColor(.white, for: .normal)
        openSettingsButton.backgroundColor = UIColor.appPurpleColor()
        
        tableView.reloadData()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func buildDatasource() -> Datasource {
        return RxTableViewSectionedReloadDataSource<ReminderSection>(configureCell: { (_, tableView, indexPath, model) -> UITableViewCell in
            let cell: ReminderCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configureCell(model: model)
            cell.enabledSwitch.rx.controlEvent(UIControl.Event.valueChanged)
                .subscribe(onNext: { [weak self] in self?.viewModel.toggleReminder(id: model.id) })
                .disposed(by: cell.disposeBag)
            return cell
        })
    }
    
    private func showDetail(model: ReminderDetail) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "ReminderDetailViewController") as? ReminderDetailViewController else { return }
        let viewModel = ReminderDetailViewModel(reminder: model)
        controller.viewModel = viewModel
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isTranslucent = false
        present(navigationController, animated: true, completion: nil)
        
        tableView.reloadData() // workaround :(
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl, completionHandler: nil)
    }
}
