//
//  ReminderViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/7/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ReminderViewController: UIViewController {

    @IBOutlet private weak var emptyViewTitleLabel: UILabel!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        Themer.shared.currentThemeRelay
            .subscribe(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureView() {
        title = "Reminders"
        
        updateColors()
        
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .backgroundColor()
        emptyViewTitleLabel.textColor = .titleTextColor()
        addButton.tintColor = .secondaryYellowColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }

}
