//
//  DetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import RxOptional
import RxSwift
import RxCocoa
import StringExtensionHTML
import Tags
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var remarkLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsView: TagsView!
    @IBOutlet weak var officialSolutionButton: UIButton!
    @IBOutlet weak var swiftButton: UIButton!
    @IBOutlet weak var markAsReadButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    
    var viewModel: DetailViewModel!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        configureContent()
        configureButtons()
        
        viewModel.scrapeSwiftSolution()
    }
    
    private func configureNavigationBar() {
        title = "Detail"
        
        let noteBarButton = UIBarButtonItem(title: "📝 Notes", style: .plain
            , target: self, action: #selector(addNotes))
        navigationItem.rightBarButtonItems = [noteBarButton]
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
            .subscribe(onNext: { [weak self] in self?.tagsView.tags = $0 })
            .disposed(by: disposeBag)
        
        viewModel.detail
            .map { $0?.articleSlug.isEmpty ?? true }
            .bind(to: officialSolutionButton.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func configureButtons() {
        markAsReadButton.layer.cornerRadius = 8
        markAsReadButton.layer.borderWidth = 1
        markAsReadButton.layer.borderColor = Configurations.highlightColor.cgColor
        markAsReadButton.setTitle("🤓 Mark as Read", for: .normal)
        markAsReadButton.setTitle("😕 Mark as Unread", for: .selected)
        markAsReadButton.setTitleColor(.white, for: .normal)
        markAsReadButton.setTitleColor(Configurations.highlightColor, for: .selected)
        
        viewModel.detail
            .filterNil()
            .map { $0.read }
            .subscribe(onNext: { [weak self] read in
                let backgroundColor = read ? Configurations.highlightColor: UIColor.white
                self?.markAsReadButton.backgroundColor = backgroundColor
                self?.markAsReadButton.isSelected = !read
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
                self.showWebpage(url: url, title: "Official Solution")
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
        
        swiftButton.rx.tap
            .withLatestFrom(viewModel.swiftSolution)
            .subscribe(onNext: { [unowned self] in
                self.showCodeController(content: $0, language: .swift)
            })
            .disposed(by: disposeBag)
    }
    
    private func showWebpage(url: URL, title: String = "") {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else { return }
        viewController.url = url
        viewController.title = title
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showCodeController(content: String?, language: Language) {
        guard let codeController = self.storyboard?.instantiateViewController(withIdentifier: "codeViewController") as? CodeViewController,
            let content = content else { return }
        codeController.viewModel = CodeViewModel(content: content, language: language)
        codeController.title = "\(language.rawValue.capitalized) Solution"
        self.navigationController?.pushViewController(codeController, animated: true)
    }
    
    @objc private func addNotes() {
        
    }
}
