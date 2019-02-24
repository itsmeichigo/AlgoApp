//
//  DetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

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
        configureView()
        
        viewModel.scrapeSwiftSolution()
    }
    
    private func configureNavigationBar() {
        title = "Detail"
        
        let noteBarButton = UIBarButtonItem(title: "📝 Notes", style: .plain
            , target: self, action: #selector(addNotes))
        navigationItem.rightBarButtonItems = [noteBarButton]
    }

    private func configureView() {
        
        titleLabel.text = viewModel.detail.title
        remarkLabel.text = viewModel.detail.remark
        difficultyLabel.text = "Difficulty: " + viewModel.detail.difficulty
        descriptionTextView.text = viewModel.detail.content.stringByDecodingHTMLEntities
        tagsView.tags = viewModel.detail.tags.joined(separator: ",")
        
        if viewModel.detail.articleSlug.isEmpty {
            officialSolutionButton.isHidden = true
        }
        
        officialSolutionButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let url = URL(string: "https://leetcode.com/articles/\(self.viewModel.detail.articleSlug)#solution") else { return }
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
        
        markAsReadButton.layer.cornerRadius = 8
        
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
