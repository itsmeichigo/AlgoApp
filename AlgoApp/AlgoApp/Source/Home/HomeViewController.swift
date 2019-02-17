//
//  ViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxDataSources
import RxSwift

final class HomeViewController: UIViewController {
    
    typealias QuestionSection = SectionModel<String, QuestionDetailModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<QuestionSection>
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    fileprivate var searchBar: UISearchBar!
    
    
    var viewModel: HomeViewModelType!
    private let currentFilter = BehaviorRelay<QuestionFilter?>(value: nil)
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
        viewModel.loadSeedDatabase()
    
        configureNavigationBar()
        configurePresentable()
    }

    private func buildDataSource() -> DataSource {
        return DataSource(configureCell: { (_, tableView, indexPath, model) -> UITableViewCell in
            let cell: HomeTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configureCell(with: model)
                return cell
        })
    }
    
    private func configureNavigationBar() {
        searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.placeholder = "Search by title"
        searchBar.rx.text.asDriver()
            .map { QuestionFilter(query: $0 ?? "", tags: [], companies: []) }
            .drive(currentFilter)
            .disposed(by: disposeBag)
        
        navigationItem.titleView = searchBar
        
        let reminderButton = UIBarButtonItem(title: "⏰", style: .plain, target: self, action: #selector(setupReminder))
        
        let settingsButton = UIBarButtonItem(title: "⚙️", style: .plain, target: self, action: #selector(showSettings))
        
        navigationItem.rightBarButtonItems = [settingsButton, reminderButton]
    }
    
    private func configurePresentable() {
        
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.separatorStyle = .none
        tableView.rx.modelSelected(QuestionDetailModel.self)
            .asDriver()
            .map { DetailViewModel(detail: $0) }
            .drive(onNext: { [unowned self] viewModel in
                guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
                viewController.viewModel = viewModel
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.questions
            .asDriver()
            .map { [QuestionSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        currentFilter
            .asDriver()
            .drive(onNext: { [unowned self] in self.viewModel.loadQuestions(filter: $0) })
            .disposed(by: disposeBag)
    
    }
    
    @objc private func setupReminder() {
        searchBar.resignFirstResponder()
    }
    
    @objc private func showFilter() {
        searchBar.resignFirstResponder()
    }
    
    @objc private func showSettings() {
        searchBar.resignFirstResponder()
    }
}

