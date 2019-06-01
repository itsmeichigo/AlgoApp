//
//  FeatureDetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/23/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import PanModal

enum FeatureType {
    case alarm
    case code
    case darkMode
    case iCloud(isEnabled: Bool)
}

class FeatureDetailViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    var mode: FeatureType = .alarm
    var dismissHandler: (() -> Void)?
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var shortFormHeight: PanModalHeight {
        let height: CGFloat = 320.0
        return .contentHeight(height)
    }
    
    var longFormHeight: PanModalHeight {
        return shortFormHeight
    }
    
    var showDragIndicator: Bool {
         return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch mode {
        case .alarm:
            logoImageView.image = UIImage(named: "alarm-clock")
            titleLabel.text = "Premium Feature"
            messageLabel.text = "Unlock Premium to get reminders \nwith coding problem everyday."
            showButton.setTitle("Tell me more 🤔", for: .normal)
        case .code:
            logoImageView.image = UIImage(named: "code")
            titleLabel.text = "Premium Feature"
            messageLabel.text = "Unlock Premium to keep your \ncode snippets for each problem."
            showButton.setTitle("Why not? 🤓", for: .normal)
        case .darkMode:
            logoImageView.image = UIImage(named: "moon")
            titleLabel.text = "Premium Feature"
            messageLabel.text = "Unlock Premium to enable Dark mode"
            showButton.setTitle("Dark mode rules 🌝", for: .normal)
        case .iCloud(let isEnabled):
            logoImageView.image = UIImage(named: "icloud")
            titleLabel.text = isEnabled ? "iCloud for AlgoKitty is enabled" : "iCloud for AlgoKitty is disabled"
            messageLabel.text = isEnabled ? "All your progress, notes and reminders can now be synced between your devices" : "Enable iCloud to sync your progress, notes and reminders between your devices"
            showButton.isHidden = true
        }
        
        showButton.layer.cornerRadius = showButton.frame.height / 2
        showButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        
        updateColors()
    }

    func updateColors() {
        view.backgroundColor = .backgroundColor()
        
        titleLabel.textColor = .titleTextColor()
        messageLabel.textColor = .subtitleTextColor()
        
        showButton.setTitleColor(.white, for: .normal)
        
        switch mode {
        case .alarm:
            showButton.backgroundColor = .appYellowColor()
        case .code:
            showButton.backgroundColor = .appBlueColor()
        case .darkMode:
            showButton.backgroundColor = .appPurpleColor()
        case .iCloud:
            showButton.backgroundColor = .appBlueColor()
        }
        
    }
    
    @objc func dismissView() {
        if presentingViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.dismissHandler?()
            }
            return
        }
        
        dismissHandler?()
    }
}
