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
    @IBOutlet weak var otherSolutionsTagView: TagsView!
    @IBOutlet weak var otherSolutionsLabel: UILabel!
    @IBOutlet weak var otherSolutionsView: UIView!
    
    @IBOutlet weak var markAsSolvedButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var viewModel: DetailViewModel!
    
    private let disposeBag = DisposeBag()
    private let tagColors: [UIColor] = [.appRedColor(), .appBlueColor(), .appGreenColor(), .appPurpleColor()]
    private let notePanel = FloatingPanelController()
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureViews()
        configureContent()
        configureButtons()
        configureNotePanel()
        
        viewModel.scrapeSolutions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.all)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func configureNotePanel() {
        notePanel.delegate = self
        notePanel.isRemovalInteractionEnabled = true
        
        notePanel.surfaceView.cornerRadius = 16.0
        notePanel.surfaceView.shadowHidden = false
        notePanel.surfaceView.grabberHandle.isHidden = true
        
        let note = viewModel.detail.value?.note
        let text = note?.isEmpty != false ? "" : note
        let language = viewModel.detail.value?.noteLanguage ?? .markdown
        let navigationController = setupCodeController(title: "", content: text, language: language, readOnly: false, delegate: self)
        
        notePanel.set(contentViewController: navigationController)
    }
    
    private func configureNavigationBar() {        
        let noteBarButton = UIBarButtonItem(image: UIImage(named: "notepad"), style: .plain, target: self, action: #selector(showNotes))
        noteBarButton.tintColor = .secondaryColor()
        navigationItem.rightBarButtonItems = [noteBarButton]
        
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(popView))
        backButton.tintColor = .subtitleTextColor()
        navigationItem.leftBarButtonItem = backButton
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self;

    }
    
    @objc private func popView() {
        navigationController?.popViewController(animated: true)
    }
    
    private func configureViews() {
        
        otherSolutionsTagView.backgroundColor = .clear
        otherSolutionsTagView.delegate = self
        tagsView.isUserInteractionEnabled = false
        
        markAsSolvedButton.layer.cornerRadius = 8
        markAsSolvedButton.setTitle("🤯 Mark as Solved", for: .normal)
        markAsSolvedButton.setTitle("🤭 Mark as Unsolved", for: .selected)
        markAsSolvedButton.setTitleColor(.white, for: .normal)
        markAsSolvedButton.setTitleColor(.white, for: .selected)
        
        feedbackGenerator.prepare()
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
        
        officialSolutionButton.setTitleColor(.secondaryColor(), for: .normal)
        
        otherSolutionsLabel.textColor = .titleTextColor()
        otherSolutionsTagView.tagLayerColor = .clear
        otherSolutionsTagView.tagBackgroundColor = UIColor.appPurpleColor().withAlphaComponent(0.1)
        otherSolutionsTagView.tagTitleColor = .appPurpleColor()
        
        loadingIndicator.style = Themer.shared.currentTheme == .light ? .gray : .white
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
        
        viewModel.githubSolutionsRelay
            .observeOn(MainScheduler.instance)
            .map { $0.keys.map { $0.rawValue }.joined(separator: ",") }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                self?.otherSolutionsTagView.tags = $0
            })
            .disposed(by: disposeBag)
    }
    
    private func configureButtons() {
        
        viewModel.detail
            .filterNil()
            .map { $0.solved }
            .subscribe(onNext: { [weak self] solved in
                let backgroundColor: UIColor = solved ? .subtitleTextColor() : .appPurpleColor()
                self?.markAsSolvedButton.backgroundColor = backgroundColor
                self?.markAsSolvedButton.isSelected = solved
            })
            .disposed(by: disposeBag)
        
        markAsSolvedButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.toggleSolved()
                self?.feedbackGenerator.selectionChanged()
            })
            .disposed(by: disposeBag)
        
        officialSolutionButton.rx.tap
            .withLatestFrom(viewModel.detail)
            .filterNil()
            .subscribe(onNext: { [unowned self] in
                guard let url = URL(string: "https://leetcode.com/articles/\($0.articleSlug)#solution") else { return }
                self.showWebpage(url: url, title: "Official Explanation", contentSelector: ".article-base")
            })
            .disposed(by: disposeBag)
        
        viewModel.scrapingSolutions
            .observeOn(MainScheduler.instance)
            .map { !$0 }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.githubSolutionsRelay
            .observeOn(MainScheduler.instance)
            .map { $0.isEmpty }
            .bind(to: otherSolutionsView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.scrapingSolutions.asDriver()
            .filter { !$0 }
            .withLatestFrom(Driver.combineLatest(viewModel.githubSolutionsRelay.asDriver(), viewModel.detail.asDriver().filterNil()))
            .map { $0.0.count > 0 || $0.1.articleSlug.isEmpty == false }
            .map { $0 == true ? "📕 Solutions" : "😓 No solution found" }
            .drive(solutionsTitleLabel.rx.text)
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
        if notePanel.parent == nil {
            notePanel.addPanel(toParent: self)
        }
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
        notePanel.removePanelFromParent(animated: true)
    }
    
    func codeControlerShouldSave(content: String, language: Language) {
        viewModel.updateNote(content, language: language)
    }
    
    func codeControllerShouldExpand() {
        notePanel.move(to: .full, animated: true)
    }
}

extension DetailViewController: TagsDelegate {
    func tagsTouchAction(_ tagsView: TagsView, tagButton: TagButton) {
        guard tagsView == otherSolutionsTagView,
            let title = tagButton.title(for: .normal) else { return }
        for (language, content) in viewModel.githubSolutionsRelay.value {
            if language.rawValue == title {
                let title = "\(language.rawValue.capitalized) Solution"
                let controller = setupCodeController(title: title, content: content, language: language)
                present(controller, animated: true, completion: nil)
                break
            }
        }
    }
}

extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
