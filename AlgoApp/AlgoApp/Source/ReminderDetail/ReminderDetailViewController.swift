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

    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var sendProblemSwitch: UISwitch!
    @IBOutlet private var titleLabels: [UILabel]!
    @IBOutlet private weak var daysStackView: UIStackView!
    
    @IBOutlet private weak var sundayButton: UIButton!
    @IBOutlet private weak var mondayButton: UIButton!
    @IBOutlet private weak var tuesdayButton: UIButton!
    @IBOutlet private weak var wednesdayButton: UIButton!
    @IBOutlet private weak var thursdayButton: UIButton!
    @IBOutlet private weak var fridayButton: UIButton!
    @IBOutlet private weak var saturdayButton: UIButton!
    
    @IBOutlet weak var datePickerTopSpace: NSLayoutConstraint!
    
    private var filterView: UIView?
    private var filterViewController: FilterViewController?
    
    var viewModel: ReminderDetailViewModel!
    
    private lazy var dayButtons: [UIButton] = [sundayButton, mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = (viewModel.reminder != nil) ? "Edit Reminder" : "Add Reminder"
        if let reminder = viewModel.reminder {
            populateViews(reminder: reminder)
        }
        
        addFilterView()
        updateColors()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func populateViews(reminder: ReminderDetail) {
        datePicker.setDate(reminder.date, animated: true)
        for (index, button) in dayButtons.enumerated() {
            if reminder.repeatDays.contains(index + 1) {
                button.isSelected = true
            }
        }
    }
    
    private func addFilterView() {
        guard let filterViewController = storyboard?.instantiateViewController(withIdentifier: "filterViewController") as? FilterViewController,
            let filterView = filterViewController.view else { return }
        filterViewController.initialFilter = viewModel.reminder?.filter
            
        view.addSubview(filterView)
        filterView.snp.makeConstraints { maker in
            maker.top.equalTo(sendProblemSwitch.snp.bottom).offset(16)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        filterView.isHidden = true
        filterViewController.scrollView.bounces = false
        filterViewController.scrollView.delegate = self
        filterViewController.updateColors()
    
        addChild(filterViewController)
        filterViewController.didMove(toParent: self)
        
        self.filterView = filterView
        self.filterViewController = filterViewController
    }
    
    private func updateColors() {
        navigationController?.navigationBar.barTintColor = .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .primaryColor()
        
        datePicker.setValue(UIColor.titleTextColor(), forKey: "textColor")
        
        cancelButton.tintColor = .subtitleTextColor()
        saveButton.tintColor = .secondaryYellowColor()
        sendProblemSwitch.onTintColor = .secondaryYellowColor()
        
        titleLabels.forEach { label in
            label.textColor = .titleTextColor()
        }
        
        dayButtons.forEach { button in
            button.setTitleColor(.secondaryYellowColor(), for: .normal)
            button.setTitleColor(.primaryColor(), for: .selected)
            button.layer.borderColor = UIColor.secondaryYellowColor().cgColor
            button.layer.borderWidth = 1
            button.layer.cornerRadius = button.bounds.height / 2
            button.backgroundColor = .clear
        }
        
        setNeedsStatusBarAppearanceUpdate()
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
                               filter: filterViewController?.currentFilter)
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.layer.borderWidth = 0
            sender.backgroundColor = UIColor.secondaryYellowColor()
        } else {
            sender.layer.borderWidth = 1
            sender.backgroundColor = .clear
        }
    }
    
    @IBAction private func sendProblemStateChange(_ sender: UISwitch) {
        filterView?.isHidden = !sender.isOn
        if !sender.isOn {
            filterViewController?.scrollView.setContentOffset(.zero, animated: false)
            datePickerTopSpace.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension ReminderDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        datePickerTopSpace.constant = offsetY > 0 ? -offsetY : CGFloat(0)
    }
}
