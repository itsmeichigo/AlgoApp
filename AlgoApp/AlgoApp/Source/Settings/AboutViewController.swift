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

        view.backgroundColor = .backgroundColor()
        configureNavigationBar()
        configureTextView()
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
    
    private func configureTextView() {
        contentTextView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentTextView.backgroundColor = .backgroundColor()
        contentTextView.linkTextAttributes = [.foregroundColor: UIColor.appBlueColor()]
        
        guard let string = contentTextView.text else { return }
        let allRange = string.startIndex..<string.endIndex
        
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttributes([.foregroundColor: UIColor.titleTextColor(), .font: UIFont.systemFont(ofSize: 15)], range: NSRange(allRange, in: string))
        
        string.enumerateSubstrings(in: string.startIndex..<string.endIndex, options: .byWords) { (substring, range, _, _) in
            if substring == "LeetCode", string[range.upperBound].isWhitespace {
                attributedString.addAttribute(.link, value: "https://leetcode.com/", range: NSRange(range, in: string))
            }
            
            if substring == "FlatIcon" {
                attributedString.addAttribute(.link, value: "https://www.flaticon.com/", range: NSRange(range, in: string))
            }
        }
        
        contentTextView.attributedText = attributedString
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
