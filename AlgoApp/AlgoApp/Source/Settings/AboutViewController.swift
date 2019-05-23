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
        return AppConfigs.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureNavigationBar() {
        
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        title = "About 🐱💻"
        
        let backButton = UIBarButtonItem(image: UIImage(named: "cancel-button"), style: .plain, target: self, action: #selector(dismissView))
        backButton.tintColor = .subtitleTextColor()
        navigationItem.leftBarButtonItem = backButton
        
    }
    
    private func configureTextView() {
        contentTextView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentTextView.backgroundColor = .backgroundColor()
        contentTextView.linkTextAttributes = [.foregroundColor: UIColor.appBlueColor()]
        
        guard let string = contentTextView.text else { return }
        let allRange = string.startIndex..<string.endIndex
        
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttributes([.foregroundColor: UIColor.titleTextColor(), .font: UIFont.preferredFont(forTextStyle: .callout)], range: NSRange(allRange, in: string))
        
        string.enumerateSubstrings(in: string.startIndex..<string.endIndex, options: .byWords) { (substring, range, _, _) in
            if substring == "LeetCode", string[range.upperBound].isWhitespace {
                attributedString.addAttribute(.link, value: "https://leetcode.com/", range: NSRange(range, in: string))
            }
            
            if substring == "FlatIcon" {
                attributedString.addAttribute(.link, value: "https://www.flaticon.com/", range: NSRange(range, in: string))
            }
        }
        
        contentTextView.attributedText = attributedString
        contentTextView.adjustsFontForContentSizeCategory = true
    }
    
    @objc private func dismissView() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
