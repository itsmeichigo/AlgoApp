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
        
        let readBarButton = UIBarButtonItem(title: "✅", style: .plain, target: self, action: #selector(markAsRead))
        let noteBarButton = UIBarButtonItem(title: "📝", style: .plain
            , target: self, action: #selector(addNotes))
        navigationItem.rightBarButtonItems = [readBarButton, noteBarButton]
        
        navigationController?.navigationBar.tintColor = UIColor(rgb: 0xE06641)
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
        
        viewModel.swiftSolutionUrl
            .asDriver()
            .map { $0 == nil }
            .drive(swiftButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        swiftButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let url = self.viewModel.swiftSolutionUrl.value else { return }
                self.showWebpage(url: url, title: "Swift Solution")
            })
            .disposed(by: disposeBag)
        
    }
    
    private func showWebpage(url: URL, title: String = "") {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else { return }
        viewController.url = url
        viewController.title = title
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func markAsRead() {
        
    }
    
    @objc private func addNotes() {
        
    }
}
