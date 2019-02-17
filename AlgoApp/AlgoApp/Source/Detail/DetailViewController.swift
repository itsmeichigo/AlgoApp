//
//  DetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/4/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Tags
import StringExtensionHTML

class DetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var remarkLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tagsView: TagsView!
    @IBOutlet weak var officialSolutionButton: UIButton!
    @IBOutlet weak var officialSolutionButtonHeight: NSLayoutConstraint!
    
    var viewModel: DetailViewModel!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureView()
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
            officialSolutionButton.clipsToBounds = true
            officialSolutionButtonHeight.constant = 0
            view.layoutIfNeeded()
        }
        
        officialSolutionButton.rx.tap
            .subscribe(onNext: { [unowned self] in self.showArticle() })
            .disposed(by: disposeBag)
    }
    
    private func showArticle() {
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController,
            let url = URL(string: "https://leetcode.com/articles/\(viewModel.detail.articleSlug)") else { return }
        viewController.url = url
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func markAsRead() {
        
    }
    
    @objc private func addNotes() {
        
    }
}
