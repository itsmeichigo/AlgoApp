//
//  CodeViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import SnapKit

class CodeViewController: UIViewController {

    private var codeTextView: UITextView!
    
    var viewModel: CodeViewModel!
    var completionHandler: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTextView()
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let closeButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissView))
        navigationItem.leftBarButtonItems = [closeButton]
        
        if !viewModel.readOnly {
            let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveContent))
            
//            let languageButton = UIBarButtonItem(title: viewModel.lan)
            
            navigationItem.rightBarButtonItems = [saveButton]
        }
    }
    
    private func configureTextView() {
        let layoutManager = viewModel.layoutManager
        let textContainer = NSTextContainer(size: view.bounds.size)
        layoutManager.addTextContainer(textContainer)
        
        codeTextView = UITextView(frame: .zero, textContainer: textContainer)
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(codeTextView)
        codeTextView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }
        
        
        if let attributedContent = viewModel.attributedContent {
            codeTextView.attributedText = attributedContent
        }
        
        codeTextView.autocorrectionType = .no
        codeTextView.isEditable = !viewModel.readOnly
    }
    
    @objc
    private func dismissView() {
        codeTextView.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func saveContent() {
        codeTextView.resignFirstResponder()
        
        let string = codeTextView.attributedText.string
        completionHandler?(string)
        dismiss(animated: true, completion: nil)
    }
}
