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
    private var currentFilter: QuestionFilter?
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
        viewModel.loadSeedDatabase()
        viewModel.loadQuestions(filter: currentFilter)
    
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
        
        navigationItem.titleView = searchBar
        
        let filterButton = UIBarButtonItem(title: "⏳", style: .plain, target: self, action: #selector(showFilter))
        
        let settingsButton = UIBarButtonItem(title: "⚙️", style: .plain, target: self, action: #selector(showSettings))
        
        navigationItem.rightBarButtonItems = [settingsButton, filterButton]
    }
    
    private func configurePresentable() {
        
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
    
    }
    
    @objc private func showFilter() {
        searchBar.resignFirstResponder()
    }
    
    @objc private func showSettings() {
        searchBar.resignFirstResponder()
    }
}

