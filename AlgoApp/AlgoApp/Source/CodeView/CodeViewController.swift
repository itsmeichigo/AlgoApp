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
    var isFullscreenCodeEditor = false
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
        
        configureNavigationBar()
        configureSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        //ask the system to start notifying when interface change
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        //add the observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged(notification:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
}

private extension CodeViewController {
    
    func configureNavigationBar() {
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        let closeButton = UIBarButtonItem(image: UIImage(named: "cancel-button"), style: .plain, target: self, action: #selector(dismissView))
        closeButton.tintColor = .subtitleTextColor()
        navigationItem.leftBarButtonItems = [closeButton]
        
        if !viewModel.readOnly {
            let saveButton = UIBarButtonItem(image: UIImage(named: "done"), style: .plain, target: self, action: #selector(saveContent))
            saveButton.tintColor = .appGreenColor()
            
            if !isFullscreenCodeEditor {
                let enlargeButton = UIBarButtonItem(image: UIImage(named: "maximize"), style: .plain, target: self, action: #selector(enlargeView))
                enlargeButton.tintColor = .appBlueColor()
                navigationItem.rightBarButtonItems = [saveButton, enlargeButton]
                
            } else {
                navigationItem.rightBarButtonItems = [saveButton]
            }
            
            viewModel.language
                .subscribe(onNext: { [weak self] in
                    self?.languageButton.setTitle($0.rawValue, for: .normal)
                })
                .disposed(by: disposeBag)
            
            languageButton.setImage(UIImage(named: "arrow-down"), for: .normal)
            languageButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 7, bottom: 0, right: 0)
            languageButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 7)
            languageButton.semanticContentAttribute = .forceRightToLeft
            
            languageButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            languageButton.frame = CGRect(x: 0, y: 0, width: 150, height: 44)
            languageButton.tintColor = .appOrangeColor()
            languageButton.addTarget(self, action: #selector(switchLanguage), for: .touchUpInside)
            navigationItem.titleView = languageButton
        }
    }
    
    func configureSubviews() {
        
        view.backgroundColor = .primaryColor()
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerView)
        pickerView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(-pickerView.bounds.height)
            maker.leading.trailing.equalToSuperview()
        }
        pickerView.backgroundColor = .backgroundColor()
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
        codeTextView.keyboardAppearance = Themer.shared.currentTheme == .light ? .light : .dark
        codeTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(codeTextView)
        codeTextView.snp.makeConstraints { maker in
            maker.top.equalTo(pickerView.snp.bottom)
            maker.leading.equalTo(view.safeAreaLayoutGuide.snp.leading)
            maker.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        if let content = viewModel.attributedContent,
            content.string.count > 0 {
            codeTextView.attributedText = content
            
            if let font = content.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                let size = UIFontDescriptor.preferredFontDescriptor(withTextStyle: AppHelper.isIpad ? .body : .callout).pointSize
                let newFont = font.withSize(size)
                let mutableString = NSMutableAttributedString(attributedString: content)
                mutableString.addAttribute(.font, value: newFont, range: NSMakeRange(0, content.length))
                
                codeTextView.attributedText = mutableString
            }
        } else {
            codeTextView.text = placeholder
        }
    }
    
    func togglePickerView(show: Bool) {
        let offset = show ? 0 : -pickerView.bounds.height
        pickerView.snp.updateConstraints { maker in
            maker.top.equalToSuperview().offset(offset)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissView() {
        codeTextView.resignFirstResponder()
        if let delegate = delegate {
            delegate.codeControllerWillDismiss()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func saveContent() {
        codeTextView.resignFirstResponder()
        
        let string = codeTextView.attributedText.string
        delegate?.codeControlerShouldSave(content: string, language: viewModel.language.value)
    }
    
    @objc func enlargeView() {
        let codeController = CodeViewController()
        codeController.viewModel = CodeViewModel(content: viewModel.content, language: viewModel.language.value, readOnly: false)
        codeController.title = title
        codeController.delegate = delegate
        codeController.isFullscreenCodeEditor = true
        
        present(UINavigationController(rootViewController: codeController), animated: true, completion: nil)
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
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-keyboardHeight + view.safeAreaInsets.bottom)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        codeTextView.snp.updateConstraints { maker in
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    @objc func orientationChanged(notification : NSNotification) {
        togglePickerView(show: false)
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let language = viewModel.languageList[row]
        viewModel.language.accept(language)
        togglePickerView(show: false)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = viewModel.languageList[row].rawValue
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()])
    }
}
