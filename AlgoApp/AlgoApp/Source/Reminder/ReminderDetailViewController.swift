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
    
    private var filterView: UIView!
    private var questionFilter: QuestionFilter?
    
    private lazy var dayButtons: [UIButton] = [sundayButton, mondayButton, tuesdayButton, wednesdayButton, thursdayButton, fridayButton, saturdayButton]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addFilterView()
        updateColors()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func addFilterView() {
        guard let filterViewController = storyboard?.instantiateViewController(withIdentifier: "filterViewController") as? FilterViewController else { return }
        filterView = filterViewController.view
        view.addSubview(filterView)
        filterView.snp.makeConstraints { maker in
            maker.top.equalTo(sendProblemSwitch.snp.bottom).offset(16)
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        filterView.isHidden = true
        
        filterViewController.updateColors()
        filterViewController.completionBlock = { [weak self] in
            self?.questionFilter = $0
        }
        addChild(filterViewController)
        filterViewController.didMove(toParent: self)
        
    }
    
    private func updateColors() {
        navigationController?.navigationBar.barTintColor = .backgroundColor()
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
            button.setTitleColor(.secondaryYellowColor(), for: .selected)
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
    
    @IBAction private func dayButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.backgroundColor = UIColor.secondaryYellowColor().withAlphaComponent(0.2)
        } else {
            sender.backgroundColor = .clear
        }
    }
    
    @IBAction private func sendProblemStateChange(_ sender: UISwitch) {
        filterView.isHidden = !sender.isOn
    }
}
