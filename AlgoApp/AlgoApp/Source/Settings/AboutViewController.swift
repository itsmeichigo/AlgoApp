//
//  AboutViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/31/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        
        contentTextView.textColor = .titleTextColor()
        contentTextView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentTextView.backgroundColor = .backgroundColor()
        
        view.backgroundColor = .backgroundColor()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureNavigationBar() {
        
        title = "About 🐱💻"
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(popView))
        backButton.tintColor = .subtitleTextColor()
        navigationItem.leftBarButtonItem = backButton
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self;
        
    }
    
    @objc private func popView() {
        navigationController?.popViewController(animated: true)
    }
}

extension AboutViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
