//
//  CodeViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import SnapKit

protocol CodeViewControllerDelegate: class {
    func codeControllerDidStartEditing()
    func codeControllerWillDismiss()
    func codeControlerShouldSave(content: String)
}

class CodeViewController: UIViewController {

    private var codeTextView: UITextView!
    
    var viewModel: CodeViewModel!
    
    weak var delegate: CodeViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTextView()
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel-button"), style: .plain, target: self, action: #selector(dismissView))
        navigationItem.leftBarButtonItems = [closeButton]
        
        if !viewModel.readOnly {
            let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveContent))
            saveButton.tintColor = Colors.secondaryBlueColor
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
        codeTextView.delegate = self
    }
    
    @objc
    private func dismissView() {
        codeTextView.resignFirstResponder()
        delegate?.codeControllerWillDismiss()
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func saveContent() {        
        let string = codeTextView.attributedText.string
        delegate?.codeControlerShouldSave(content: string)
    }
}

extension CodeViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.codeControllerDidStartEditing()
    }
}
