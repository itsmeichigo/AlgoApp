//
//  CodeViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift

protocol CodeViewControllerDelegate: class {
    func codeControllerShouldExpand()
    func codeControllerWillDismiss()
    func codeControlerShouldSave(content: String, language: Language)
}

class CodeViewController: UIViewController {
    
    var viewModel: CodeViewModel!
    weak var delegate: CodeViewControllerDelegate?
    
    private var codeTextView: UITextView!
    private let languageButton = UIButton(type: .system)
    private let pickerView = UIPickerView(frame: .zero)
    
    private let disposeBag = DisposeBag()
    private let placeholder =  """
        // start writing here
        // choose your preferred language for appropriate syntax highlight
        """
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubviews()
        configureNavigationBar()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

private extension CodeViewController {
    
    func configureNavigationBar() {
        
        navigationController?.navigationBar.isTranslucent = false
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel-button"), style: .plain, target: self, action: #selector(dismissView))
        closeButton.tintColor = Colors.lightGrey
        navigationItem.leftBarButtonItems = [closeButton]
        
        if !viewModel.readOnly {
            let saveButton = UIBarButtonItem(image: UIImage(named: "done"), style: .plain, target: self, action: #selector(saveContent))
            saveButton.tintColor = Colors.secondaryGreenColor
            navigationItem.rightBarButtonItems = [saveButton]
            
            viewModel.language
                .subscribe(onNext: { [weak self] in
                    self?.languageButton.setTitle($0.rawValue, for: .normal)
                })
                .disposed(by: disposeBag)
            
            languageButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            languageButton.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
            languageButton.tintColor = Colors.secondaryOrangeColor
            languageButton.addTarget(self, action: #selector(switchLanguage), for: .touchUpInside)
            navigationItem.titleView = languageButton
        }
    }
    
    func configureSubviews() {
        
        view.backgroundColor = Colors.background
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)
        pickerView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(-216)
            maker.leading.trailing.equalToSuperview()
        }
        pickerView.backgroundColor = .white
        pickerView.dataSource = self
        pickerView.delegate = self
        if let index = viewModel.languageList.firstIndex(where: { $0 == self.viewModel.language.value }) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        
        let size = UIScreen.main.bounds.size
        viewModel.layoutManager
            .filterNil()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                let textContainer = NSTextContainer(size: size)
                $0.addTextContainer(textContainer)
                
                self.configureTextView(with: textContainer)
            })
            .disposed(by: disposeBag)
    }
    
    func configureTextView(with textContainer: NSTextContainer) {
        if codeTextView != nil {
            viewModel.content = codeTextView.attributedText.string
            codeTextView.removeFromSuperview()
        }
        
        codeTextView = UITextView(frame: .zero, textContainer: textContainer)
        codeTextView.backgroundColor = .clear
        codeTextView.autocorrectionType = .no
        codeTextView.isEditable = !viewModel.readOnly
        codeTextView.delegate = self
        codeTextView.font = UIFont.systemFont(ofSize: 16)
        
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(codeTextView)
        codeTextView.snp.makeConstraints { maker in
            maker.top.equalTo(pickerView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().offset(0)
        }
        
        if let content = viewModel.attributedContent,
            content.string.count > 0 {
            codeTextView.attributedText = content
        } else {
            codeTextView.text = placeholder
        }
    }
    
    func togglePickerView(show: Bool) {
        let offset = show ? 0 : -216
        pickerView.snp.updateConstraints { maker in
            maker.top.equalToSuperview().offset(offset)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissView() {
        codeTextView.resignFirstResponder()
        delegate?.codeControllerWillDismiss()
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveContent() {
        codeTextView.resignFirstResponder()
        
        let string = codeTextView.attributedText.string
        delegate?.codeControlerShouldSave(content: string, language: viewModel.language.value)
        delegate?.codeControllerWillDismiss()
    }
    
    @objc func switchLanguage() {
        codeTextView.resignFirstResponder()
        delegate?.codeControllerShouldExpand()
        togglePickerView(show: true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        codeTextView.snp.updateConstraints { maker in
            maker.bottom.equalToSuperview().offset(-keyboardHeight)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        codeTextView.snp.updateConstraints { maker in
            maker.bottom.equalToSuperview().offset(0)
        }
    }
}

extension CodeViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = ""
        }
        delegate?.codeControllerShouldExpand()
        togglePickerView(show: false)
    }
}

extension CodeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.languageList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.languageList[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let language = viewModel.languageList[row]
        viewModel.language.accept(language)
        togglePickerView(show: false)
    }
}
