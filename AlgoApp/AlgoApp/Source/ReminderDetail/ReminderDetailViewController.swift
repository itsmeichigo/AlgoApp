//
//  ReminderDetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/9/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ReminderDetailViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var sendProblemSwitch: UISwitch!
    @IBOutlet private weak var daysStackView: UIStackView!
    @IBOutlet private var titleLabels: [UILabel]!
    @IBOutlet private weak var problemsCountLabel: UILabel!
    
    @IBOutlet private weak var sundayButton: UIButton!
    @IBOutlet private weak var mondayButton: UIButton!
    @IBOutlet private weak var tuesdayButton: UIButton!
    @IBOutlet private weak var wednesdayButton: UIButton!
    @IBOutlet private weak var thursdayButton: UIButton!
    @IBOutlet private weak var fridayButton: UIButton!
    @IBOutlet private weak var saturdayButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonHeight: NSLayoutConstraint!
    
    @IBOutlet weak var filterContainerView: UIView!
    @IBOutlet weak var filterContainerViewHeight: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    private var filterViewController: FilterViewController?
    
    var viewModel: ReminderDetailViewModel!
    
    private lazy var dayButtons: [UIButton] = [sundayButton, mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFilterView()
        configureView()
        updateColors()

        if let reminder = viewModel.reminder {
            populateViews(reminder: reminder)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFilterViewHeight(isShowing: sendProblemSwitch.isOn, animated: false)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureView() {
        title = (viewModel.reminder != nil) ? "Edit Reminder" : "Add Reminder"

        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showDeleteAlert() })
            .disposed(by: disposeBag)
        
        if let controller = filterViewController {
            Driver.combineLatest(controller.currentFilterDriver, sendProblemSwitch.rx.isOn.asDriver(), AppConfigs.shared.showsReadProblemDriver)
                .map { [weak self] tuple -> Int in
                    let (filter, onSwitch, showsReadProblems) = tuple
                    return self?.viewModel.countProblems(with: (onSwitch ? filter : nil), onlyUnread: !showsReadProblems) ?? 0
                }
                .map { "\($0) problems found" }
                .drive(problemsCountLabel.rx.text)
                .disposed(by: disposeBag)
            
            saveButton.rx.tap
                .withLatestFrom(controller.currentFilterDriver)
                .subscribe(onNext: { [weak self] filter in
                    self?.saveReminder(filter: filter)
                })
                .disposed(by: disposeBag)
        } else {
            problemsCountLabel.isHidden = true
            
            saveButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.saveReminder()
                })
                .disposed(by: disposeBag)
        }
        
        sendProblemSwitch.rx.isOn
            .subscribe(onNext: { [weak self] isOn in
                self?.filterContainerView.isHidden = !isOn
                self?.updateFilterViewHeight(isShowing: isOn)
            })
            .disposed(by: disposeBag)
        
        dayButtons.forEach { button in
            button.rx.tap.asDriver()
                .map { !button.isSelected }
                .do(onNext: { selected in
                    let color = selected ? UIColor.secondaryColor() : UIColor.secondaryColor().withAlphaComponent(0.1)
                    button.backgroundColor = color
                })
                .drive(button.rx.isSelected)
                .disposed(by: disposeBag)
        }
    }
    
    private func populateViews(reminder: ReminderDetail) {
        deleteButtonHeight.constant = 50
        datePicker.setDate(reminder.date, animated: true)
        for (index, button) in dayButtons.enumerated() {
            if reminder.repeatDays.contains(index + 1) {
                button.sendActions(for: UIControl.Event.touchUpInside)
            }
        }
        sendProblemSwitch.isOn = reminder.filter?.allFilters.isEmpty == false
        sendProblemSwitch.sendActions(for: UIControl.Event.valueChanged)
    }
    
    private func addFilterView() {
        filterContainerView.isHidden = true
        
        guard let filterViewController = storyboard?.instantiateViewController(withIdentifier: "filterViewController") as? FilterViewController,
            let filterView = filterViewController.view else { return }
        filterViewController.initialFilter = viewModel.reminder?.filter
            
        filterContainerView.addSubview(filterView)
        filterView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        filterViewController.updateColors()
    
        addChild(filterViewController)
        filterViewController.didMove(toParent: self)
        
        self.filterViewController = filterViewController
    }
    
    private func updateColors() {
        navigationController?.navigationBar.barTintColor = .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .primaryColor()
        
        datePicker.setValue(UIColor.titleTextColor(), forKey: "textColor")
        
        cancelButton.tintColor = .subtitleTextColor()
        saveButton.tintColor = .appBlueColor()
        sendProblemSwitch.onTintColor = .secondaryColor()
        
        problemsCountLabel.textColor = .subtitleTextColor()
        titleLabels.forEach { label in
            label.textColor = .titleTextColor()
        }
        
        dayButtons.forEach { button in
            button.setTitleColor(.secondaryColor(), for: .normal)
            button.setTitleColor(.primaryColor(), for: .selected)
            button.layer.cornerRadius = button.bounds.height / 2
            button.backgroundColor = UIColor.secondaryColor().withAlphaComponent(0.1)
        }
        
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .appRedColor()
        deleteButton.layer.cornerRadius = 8.0
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func updateFilterViewHeight(isShowing: Bool, animated: Bool = true) {
        if let controller = filterViewController {
            let height = isShowing ? controller.scrollView.contentSize.height : max(0, scrollView.bounds.height - filterContainerView.frame.origin.y - deleteButtonHeight.constant - 16 * 2)
            filterContainerViewHeight.constant = height
            UIView.animate(withDuration: (animated ? 0.3 : 0.0)) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func showDeleteAlert() {
        let alert = UIAlertController(title: "Delete Reminder", message: "Are you sure you want to remove this reminder?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes", style: .default) { [unowned self] _ in
            self.viewModel.deleteReminder()
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func saveReminder(filter: QuestionFilter? = nil) {
        var repeatDays: [Int] = []
        for (index, button) in dayButtons.enumerated() {
            if button.isSelected {
                repeatDays.append(index + 1)
            }
        }
        
        viewModel.saveReminder(date: datePicker.date,
                               repeatDays: repeatDays,
                               filter: sendProblemSwitch.isOn ? filter : nil)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
