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
    
    private var viewModel: FilterViewModel!
    private let disposeBag = DisposeBag()
    
    var initialFilter: QuestionFilter?
    var completionBlock: ((QuestionFilter) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = FilterViewModel()
        
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
        }
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
        if tagButton.backgroundColor != Configurations.highlightColor {
            tagButton.backgroundColor = Configurations.highlightColor
            tagButton.setTitleColor(.white, for: .normal)
        } else {
            tagButton.backgroundColor = .white
            tagButton.setTitleColor(Configurations.highlightColor, for: .normal)
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
