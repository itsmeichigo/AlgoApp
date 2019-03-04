//
//  DetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Hero
import RxOptional
import RxSwift
import RxCocoa
import StringExtensionHTML
import FloatingPanel
import Tags
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var remarkLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    @IBOutlet weak var descriptionTitleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var tagTitleLabel: UILabel!
    @IBOutlet weak var tagsView: TagsView!
    
    @IBOutlet weak var solutionsTitleLabel: UILabel!
    @IBOutlet weak var officialSolutionButton: UIButton!
    @IBOutlet weak var swiftButton: UIButton!
    
    @IBOutlet weak var markAsReadButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    
    var viewModel: DetailViewModel!
    private let disposeBag = DisposeBag()
    private let tagColors: [UIColor] = [.secondaryPinkColor(), .secondaryYellowColor(), .secondaryBlueColor(), .secondaryGreenColor(), .secondaryPurpleColor()]
    private let notePanel = FloatingPanelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureViews()
        configureContent()
        configureButtons()
        configureNotePanel()
        
        viewModel.scrapeSwiftSolution()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureNotePanel() {
        notePanel.delegate = self
        notePanel.surfaceView.cornerRadius = 8.0
        notePanel.surfaceView.shadowHidden = false
        notePanel.surfaceView.grabberHandle.backgroundColor = .clear
        
        let note = viewModel.detail.value?.note
        let text = note?.isEmpty != false ? "" : note
        let language = viewModel.detail.value?.noteLanguage ?? .markdown
        let navigationController = setupCodeController(title: "", content: text, language: language, readOnly: false, delegate: self)
        
        notePanel.set(contentViewController: navigationController)
        notePanel.addPanel(toParent: self)
        notePanel.hide()
    }
    
    private func configureNavigationBar() {
        title = "Detail"
        
        let noteBarButton = UIBarButtonItem(image: UIImage(named: "notepad"), style: .plain, target: self, action: #selector(showNotes))
        noteBarButton.tintColor = .secondaryYellowColor()
        navigationItem.rightBarButtonItems = [noteBarButton]        
    }
    
    private func configureViews() {
        
        markAsReadButton.layer.cornerRadius = 8
        markAsReadButton.setTitle("🤓 Mark as Read", for: .normal)
        markAsReadButton.setTitle("😕 Mark as Unread", for: .selected)
        markAsReadButton.setTitleColor(.white, for: .normal)
        markAsReadButton.setTitleColor(.white, for: .selected)
        
        updateColors()
    }
    
    private func updateColors() {
        view.backgroundColor = .backgroundColor()
        loadingView.backgroundColor = .backgroundColor()
        
        remarkLabel.textColor = .subtitleTextColor()
        difficultyLabel.textColor = .subtitleTextColor()
        
        titleLabel.textColor = .titleTextColor()
        descriptionTextView.textColor = .titleTextColor()
        descriptionTitleLabel.textColor = .titleTextColor()
        tagTitleLabel.textColor = .titleTextColor()
        solutionsTitleLabel.textColor = .titleTextColor()
        
        officialSolutionButton.setTitleColor(.secondaryBlueColor(), for: .normal)
        swiftButton.setTitleColor(.secondaryOrangeColor(), for: .normal)
    }

    private func configureContent() {
        
        viewModel.detail
            .map { $0?.title }
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.remark }
            .bind(to: remarkLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.difficulty ?? "" }
            .map { "Difficulty: " + $0 }
            .bind(to: difficultyLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.content.stringByDecodingHTMLEntities }
            .bind(to: descriptionTextView.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.tags.joined(separator: ",") ?? "" }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tagsView.tags = $0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    for (index, tagButton) in self.tagsView.tagArray.enumerated() {
                        let currentColor = self.tagColors[index % self.tagColors.count]
                        tagButton.setTitleColor(currentColor, for: .normal)
                        tagButton.backgroundColor = currentColor.withAlphaComponent(0.1)
                        tagButton.layer.borderColor = UIColor.clear.cgColor
                    }
                })
            })
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.articleSlug.isEmpty == false }
            .map { !$0 }
            .bind(to: officialSolutionButton.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func configureButtons() {
        
        viewModel.detail
            .filterNil()
            .map { $0.read }
            .subscribe(onNext: { [weak self] read in
                let backgroundColor: UIColor = read ? .subtitleTextColor() : .secondaryPurpleColor()
                self?.markAsReadButton.backgroundColor = backgroundColor
                self?.markAsReadButton.isSelected = read
            })
            .disposed(by: disposeBag)
        
        markAsReadButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.viewModel.toggleRead() })
            .disposed(by: disposeBag)
        
        officialSolutionButton.rx.tap
            .withLatestFrom(viewModel.detail)
            .filterNil()
            .subscribe(onNext: { [unowned self] in
                guard let url = URL(string: "https://leetcode.com/articles/\($0.articleSlug)#solution") else { return }
                self.showWebpage(url: url, title: "Official Solution", contentSelector: ".article-body")
            })
            .disposed(by: disposeBag)
        
        viewModel.scrapingSolution
            .observeOn(MainScheduler.instance)
            .map { !$0 }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.swiftSolution
            .asDriver()
            .map { $0 == nil }
            .drive(swiftButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.scrapingSolution.asDriver()
            .filter { !$0 }
            .withLatestFrom(Driver.combineLatest(viewModel.swiftSolution.asDriver(), viewModel.detail.asDriver()))
            .map { $0.0 != nil || $0.1?.articleSlug.isEmpty == false }
            .map { $0 == true ? "📕 Solutions" : "😓 No solution found" }
            .drive(solutionsTitleLabel.rx.text)
            .disposed(by: disposeBag)
        
        swiftButton.rx.tap
            .withLatestFrom(viewModel.swiftSolution)
            .map { [unowned self] in
                let language = Language.swift
                let title = "\(language.rawValue.capitalized) Solution"
                return self.setupCodeController(title: title, content: $0, language: language)
            }
            .subscribe(onNext: { [unowned self] in
                self.present($0, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func showWebpage(url: URL, title: String = "", contentSelector: String?) {
        let viewController = WebViewController()
        viewController.url = url
        viewController.title = title
        viewController.contentSelector = contentSelector
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func setupCodeController(title: String?, content: String?, language: Language, readOnly: Bool = true, fullScreen: Bool = true, delegate: CodeViewControllerDelegate? = nil) -> UINavigationController {
        let codeController = CodeViewController()
        codeController.viewModel = CodeViewModel(content: (content ?? ""), language: language, readOnly: readOnly)
        codeController.title = title
        codeController.delegate = delegate
        
        return UINavigationController(rootViewController: codeController)
    }
    
    @objc private func showNotes() {
        notePanel.move(to: .full, animated: true)
    }
}

extension DetailViewController: FloatingPanelControllerDelegate {
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        if notePanel.position != .full {
            view.endEditing(true)
        }
    }
}

extension DetailViewController: CodeViewControllerDelegate {
    func codeControllerWillDismiss() {
        notePanel.hide(animated: true, completion: nil)
    }
    
    func codeControlerShouldSave(content: String, language: Language) {
        viewModel.updateNote(content, language: language)
    }
    
    func codeControllerShouldExpand() {
        notePanel.move(to: .full, animated: true)
    }
}
