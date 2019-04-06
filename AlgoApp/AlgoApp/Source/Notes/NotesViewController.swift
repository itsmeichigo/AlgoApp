//
//  NotesViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 4/6/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NotesViewController: UIViewController {

    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appOrangeColor()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
        
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func configureView() {
        
    }
}
