//
//  ReminderDetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/9/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import SnapKit

class ReminderDetailViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var sendProblemSwitch: UISwitch!
    @IBOutlet private weak var daysStackView: UIStackView!
    @IBOutlet private var titleLabels: [UILabel]!
    
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
    
    private var filterViewController: FilterViewController?
    
    var viewModel: ReminderDetailViewModel!
    
    private lazy var dayButtons: [UIButton] = [sundayButton, mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        addFilterView()
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
    
    private func configureNavigationBar() {
        title = (viewModel.reminder != nil) ? "Edit Reminder" : "Add Reminder"
    }
    
    private func populateViews(reminder: ReminderDetail) {
        deleteButtonHeight.constant = 50
        datePicker.setDate(reminder.date, animated: true)
        for (index, button) in dayButtons.enumerated() {
            if reminder.repeatDays.contains(index + 1) {
                dayButtonTapped(button)
            }
        }
        sendProblemSwitch.isOn = reminder.filter?.allFilters.isEmpty == false
        sendProblemStateChange(sendProblemSwitch)
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
        saveButton.tintColor = .secondaryBlueColor()
        sendProblemSwitch.onTintColor = .secondaryYellowColor()
        
        titleLabels.forEach { label in
            label.textColor = .titleTextColor()
        }
        
        dayButtons.forEach { button in
            button.setTitleColor(.secondaryYellowColor(), for: .normal)
            button.setTitleColor(.primaryColor(), for: .selected)
            button.layer.cornerRadius = button.bounds.height / 2
            button.backgroundColor = UIColor.secondaryYellowColor().withAlphaComponent(0.1)
        }
        
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .secondaryRedColor()
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

    @IBAction private func dismissView(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func saveReminder(_ sender: Any) {
        var repeatDays: [Int] = []
        for (index, button) in dayButtons.enumerated() {
            if button.isSelected {
                repeatDays.append(index + 1)
            }
        }
        
        viewModel.saveReminder(date: datePicker.date,
                               repeatDays: repeatDays,
                               filter: sendProblemSwitch.isOn ? filterViewController?.currentFilter : nil)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.backgroundColor = UIColor.secondaryYellowColor()
        } else {
            sender.backgroundColor = UIColor.secondaryYellowColor().withAlphaComponent(0.1)
        }
    }
    
    @IBAction private func sendProblemStateChange(_ sender: UISwitch) {
        filterContainerView.isHidden = !sender.isOn
        updateFilterViewHeight(isShowing: sender.isOn)
    }
    
    @IBAction func deleteReminder(_ sender: Any) {
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
}
