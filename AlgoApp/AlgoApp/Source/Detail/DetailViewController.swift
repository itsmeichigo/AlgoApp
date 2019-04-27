//
//  DetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import PanModal
import RxOptional
import RxSwift
import RxCocoa
import StringExtensionHTML
import FloatingPanel
import Tags
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var remarkLabel: UILabel!
    @IBOutlet private weak var difficultyLabel: UILabel!
    
    @IBOutlet private weak var descriptionTitleLabel: UILabel!
    @IBOutlet private weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet private weak var solutionsTitleLabel: UILabel!
    @IBOutlet private weak var officialSolutionButton: UIButton!
    @IBOutlet private weak var otherSolutionsTagView: TagsView!
    @IBOutlet private weak var otherSolutionsLabel: UILabel!
    @IBOutlet private weak var otherSolutionsView: UIView!
    
    @IBOutlet private weak var markAsSolvedButton: UIButton!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    
    var viewModel: DetailViewModel!
    var shouldShowNote = false
    
    private let disposeBag = DisposeBag()
    private let tagColors: [UIColor] = [.appRedColor(), .appYellowColor(), .appBlueColor(), .appGreenColor(), .appOrangeColor(), .appPurpleColor()]
    
    private let notePanel = FloatingPanelController()
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    
    private let saveButton = UIButton(type: .system)
    private let noteButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureViews()
        configureContent()
        configureButtons()
        configureNotePanel()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowNote {
            shouldShowNote = false
            showNotes()
        } else {
            codeControllerWillDismiss()
        }
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
    }
    
    private func updateNotePanelContent(_ content: String?) {
        let text = content?.isEmpty != false ? "" : content
        let language = viewModel.detail.value?.noteLanguage ?? .markdown
        let navigationController = setupCodeController(title: "", content: text, language: language, readOnly: false, delegate: self)
        
        notePanel.set(contentViewController: navigationController)
    }
    
    private func configureNavigationBar() {
        noteButton.setImage(UIImage(named: "notepad"), for: .normal)
        noteButton.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
        noteButton.tintColor = .appYellowColor()
        noteButton.addTarget(self, action: #selector(showNotes), for: .touchUpInside)
        
        let noteBarButton = UIBarButtonItem(customView: noteButton)
        
        saveButton.setImage(UIImage(named: "bookmark"), for: .normal)
        saveButton.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
        saveButton.tintColor = .appBlueColor()
        let saveBarButton = UIBarButtonItem(customView: saveButton)
        
        let linkBarButton = UIBarButtonItem(image: UIImage(named: "link"), style: .plain, target: self, action: #selector(showLeetCode))
        linkBarButton.tintColor = .appGreenColor()
        
        navigationItem.rightBarButtonItems = [noteBarButton, saveBarButton, linkBarButton]
        
    }
    
    private func configureViews() {
        
        otherSolutionsTagView.backgroundColor = .clear
        otherSolutionsTagView.paddingVertical = 6.0
        otherSolutionsTagView.paddingHorizontal = 10.0
        otherSolutionsTagView.tagFont = UIFont.preferredFont(forTextStyle: AppHelper.isIpad ? .body : .callout)
        otherSolutionsTagView.delegate = self
        
        markAsSolvedButton.layer.cornerRadius = 8
        markAsSolvedButton.setTitle("🤯 Mark as Solved", for: .normal)
        markAsSolvedButton.setTitle("🤭 Mark as Unsolved", for: .selected)
        markAsSolvedButton.setTitleColor(.white, for: .normal)
        markAsSolvedButton.setTitleColor(.white, for: .selected)
        
        descriptionTextView.adjustsFontForContentSizeCategory = true
        
        feedbackGenerator.prepare()
        updateColors()
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
        view.backgroundColor = .backgroundColor()
        loadingView.backgroundColor = .backgroundColor()
        
        remarkLabel.textColor = .appOrangeColor()
        difficultyLabel.textColor = .appOrangeColor()
        
        titleLabel.textColor = .titleTextColor()
        descriptionTextView.textColor = .titleTextColor()
        descriptionTitleLabel.textColor = .titleTextColor()
        tagsLabel.textColor = .subtitleTextColor()
        solutionsTitleLabel.textColor = .titleTextColor()
        
        officialSolutionButton.setTitleColor(.appOrangeColor(), for: .normal)
        
        otherSolutionsLabel.textColor = .subtitleTextColor()
        otherSolutionsTagView.tagLayerColor = .clear
        otherSolutionsTagView.tagBackgroundColor = .clear
        otherSolutionsTagView.tagTitleColor = .clear
        
        loadingIndicator.style = Themer.shared.currentTheme == .light ? .gray : .white
    }

    private func configureContent() {
        
        viewModel.detail
            .filterNil()
            .distinctUntilChanged { $0.id == $1.id }
            .subscribe(onNext: { [weak self] in self?.viewModel.scrapeSolutions(detail: $0) })
            .disposed(by: disposeBag)
        
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
            .map { $0?.content.stringByDecodingHTMLEntities.formattedDescription }
            .bind(to: descriptionTextView.rx.attributedText)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.tags.joined(separator: "・") ?? "" }
            .map { $0.isEmpty ? $0 : "🏷 \($0)" }
            .bind(to: tagsLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.articleSlug.isEmpty == false }
            .map { !$0 }
            .bind(to: officialSolutionButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.githubSolutionsRelay
            .observeOn(MainScheduler.instance)
            .map { $0.keys.map { $0.rawValue }.joined(separator: ",") }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.otherSolutionsTagView.tags = $0
                self.updateSolutionViewColors()
            })
            .disposed(by: disposeBag)
        
        viewModel.detail.asDriver()
            .map { $0?.note }
            .drive(onNext: { [weak self] in self?.updateNotePanelContent($0) })
            .disposed(by: disposeBag)
    }
    
    private func updateSolutionViewColors() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for (index, tagButton) in self.otherSolutionsTagView.tagArray.enumerated() {
                let currentColor = self.tagColors[index % self.tagColors.count]
                tagButton.setTitleColor(currentColor, for: .normal)
                tagButton.backgroundColor = currentColor.withAlphaComponent(0.1)
                tagButton.layer.borderColor = UIColor.clear.cgColor
            }
        }
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
    
        viewModel.detail.asDriver()
            .filterNil()
            .map { $0.saved ? "bookmarked" : "bookmark" }
            .map { UIImage(named: $0) }
            .drive(onNext: { [weak self] in
                self?.saveButton.setImage($0, for: .normal)
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.toggleSaved()
            })
            .disposed(by: disposeBag)
    }
    
    private func showWebpage(url: URL, title: String = "", contentSelector: String?) {
        let viewController = WebViewController()
        viewController.hidesBottomBarWhenPushed = true
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
    
    private func showPremiumPopup() {
        guard presentedViewController == nil,
            let controller = AppHelper.settingsStoryboard.instantiateViewController(withIdentifier: "PremiumAlertViewController") as? PremiumAlertViewController else { return }
        
        controller.mode = .code
        controller.dismissHandler = { [weak self] in self?.presentPremiumDetail() }
        
        presentPanModal(controller, sourceView: noteButton, sourceRect: CGRect(x: noteButton.frame.width / 2, y: noteButton.frame.height, width: 0, height: 0))
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }
    
    private func presentPremiumDetail() {
        let detailController = AppHelper.settingsStoryboard.instantiateViewController(withIdentifier: "PremiumDetailNavigationController")
        present(detailController, animated: true, completion: nil)
    }
    
    @objc private func showNotes() {

        if AppHelper.isIpad && !AppConfigs.shared.isPremium {
            showPremiumPopup()
            return
        }
        
        if notePanel.parent == nil {
            notePanel.addPanel(toParent: self)
        }
        notePanel.move(to: .full, animated: true)
    }
    
    @objc func showLeetCode() {
        guard let path = viewModel.detail.value?.titleSlug,
            let url = URL(string: "https://leetcode.com/problems/\(path)"),
            UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        if !AppConfigs.shared.isPremium {
            showPremiumPopup()
            return
        }
        
        viewModel.updateNote(content, language: language)
        notePanel.removePanelFromParent(animated: true)
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
