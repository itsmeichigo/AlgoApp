//
//  FilterViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/20/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Tags

class FilterViewController: UIViewController {

    @IBOutlet weak var difficultyTagsView: TagsView!
    @IBOutlet weak var categoryTagsView: TagsView!
    @IBOutlet weak var companyTagsView: TagsView!
    @IBOutlet weak var otherTagsView: TagsView!
    
    @IBOutlet weak var clearAllButton: UIBarButtonItem!
    @IBOutlet weak var applyButton: UIBarButtonItem!
    
    @IBOutlet var titleLabels: [UILabel]!
    
    private var viewModel: FilterViewModel!
    private let disposeBag = DisposeBag()
    
    var initialFilter: QuestionFilter?
    var completionBlock: ((QuestionFilter) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = FilterViewModel()
        
        applyButton.tintColor = .secondaryBlueColor()
        clearAllButton.tintColor = .secondaryPinkColor()
        
        difficultyTagsView.tags = Question.DifficultyLevel.allCases.map { $0.title }.joined(separator: ",")
        
        otherTagsView.tags = Question.Remarks.allCases.map { $0.title }.joined(separator: ",")
        
        viewModel.allTags.asDriver()
            .drive(onNext: { [weak self] in
                self?.categoryTagsView.tags = $0.joined(separator: ",")
            })
            .disposed(by: disposeBag)
        
        viewModel.allCompanies.asDriver()
            .drive(onNext: { [weak self] in
                self?.companyTagsView.tags = $0.joined(separator: ",")
            })
            .disposed(by: disposeBag)
        
        [difficultyTagsView, otherTagsView, categoryTagsView, companyTagsView].forEach { [unowned self] tagView in
            tagView?.delegate = self
            tagView?.tagLayerColor = .borderColor()
            tagView?.tagTitleColor = .titleTextColor()
            tagView?.backgroundColor = .clear
        }
        
        updateColors()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let filter = initialFilter {
            loadInitialFilter(filter)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: true, completion: nil)
    }
    
    private func loadInitialFilter(_ filter: QuestionFilter) {
        for level in filter.levels {
            if let button = difficultyTagsView.tagArray.first(where: { $0.title(for: .normal) == level.title }) {
                tagsTouchAction(difficultyTagsView, tagButton: button)
            }
        }
        
        for tag in filter.tags {
            if let button = categoryTagsView.tagArray.first(where: { $0.title(for: .normal) == tag }) {
                tagsTouchAction(categoryTagsView, tagButton: button)
            }
        }
        
        for company in filter.companies {
            if let button = companyTagsView.tagArray.first(where: { $0.title(for: .normal) == company }) {
                tagsTouchAction(companyTagsView, tagButton: button)
            }
        }
        
        if filter.topLiked, let button = otherTagsView.tagArray.first(where: { $0.title(for: .normal) == Question.Remarks.topLiked.title }) {
            tagsTouchAction(otherTagsView, tagButton: button)
        }
        
        if filter.topInterviewed, let button = otherTagsView.tagArray.first(where: { $0.title(for: .normal) == Question.Remarks.topInterviewed.title }) {
            tagsTouchAction(otherTagsView, tagButton: button)
        }
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .primaryColor()
        
        titleLabels.forEach { $0.textColor = .titleTextColor() }
    }

    @IBAction func clearAllFilters(_ sender: Any) {
        let filter = viewModel.buildFilter(shouldClearAll: true)
        completionBlock?(filter)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func applyFilters(_ sender: Any) {
        let filter = viewModel.buildFilter(shouldClearAll: false)
        completionBlock?(filter)
        dismiss(animated: true, completion: nil)
    }
}

extension FilterViewController: TagsDelegate {
    func tagsTouchAction(_ tagsView: TagsView, tagButton: TagButton) {
        if tagButton.layer.borderColor != UIColor.clear.cgColor {
            tagButton.backgroundColor = .titleTextColor()
            tagButton.setTitleColor(.primaryColor(), for: .normal)
            tagButton.layer.borderColor = UIColor.clear.cgColor
        } else {
            tagButton.backgroundColor = .backgroundColor()
            tagButton.setTitleColor(.titleTextColor(), for: .normal)
            tagButton.layer.borderColor = UIColor.borderColor().cgColor
        }
        
        let title = tagButton.title(for: .normal)!
        if tagsView == difficultyTagsView {
            viewModel.updateLevel(title)
        } else if tagsView == categoryTagsView {
            viewModel.updateCategory(title)
        } else if tagsView == companyTagsView {
            viewModel.updateCompany(title)
        } else if tagsView == otherTagsView {
            viewModel.updateRemark(title)
        }
    }
}
