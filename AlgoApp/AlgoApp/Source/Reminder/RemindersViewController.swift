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
    
    @IBOutlet private weak var emptyImageView: UIImageView!
    @IBOutlet private weak var emptyTitleLabel: UILabel!
    @IBOutlet private weak var addButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    
    private let disposeBag = DisposeBag()
    private let viewModel = RemindersViewModel()
    
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
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        
        viewModel.reminders.asDriver()
            .map { [ReminderSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        viewModel.reminders.asDriver()
            .map { !$0.isEmpty }
            .drive(emptyTitleLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.reminders.asDriver()
            .map { !$0.isEmpty }
            .drive(emptyImageView.rx.isHidden)
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
        emptyTitleLabel.textColor = .subtitleTextColor()
        addButton.tintColor = .secondaryColor()
        
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
}
