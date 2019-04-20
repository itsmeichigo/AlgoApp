//
//  PremiumAlertViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/23/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import PanModal

enum PremiumFeature: Int {
    case alarm
    case code
    case darkMode
}

class PremiumAlertViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    var mode: PremiumFeature = .alarm
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
            messageLabel.text = "Unlock Premium to get reminders \nwith coding problem everyday."
            showButton.setTitle("Tell me more 🤔", for: .normal)
        case .code:
            logoImageView.image = UIImage(named: "code")
            messageLabel.text = "Unlock Premium to keep your \ncode snippets for each problem."
            showButton.setTitle("Why not? 🤓", for: .normal)
        case .darkMode:
            logoImageView.image = UIImage(named: "moon")
            messageLabel.text = "Unlock Premium to enable Dark mode"
            showButton.setTitle("Dark mode rules 🌝", for: .normal)
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
