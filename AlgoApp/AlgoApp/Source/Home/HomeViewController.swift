//
//  ViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Hero
import UIKit
import RxCocoa
import RxDataSources
import RxSwift

final class HomeViewController: UIViewController {
    
    typealias QuestionSection = SectionModel<String, QuestionCellModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<QuestionSection>
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    fileprivate var searchBar: UISearchBar!
    
    var viewModel: HomeViewModel!
    
    private let currentFilter = BehaviorRelay<QuestionFilter?>(value: nil)
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
        viewModel.loadSeedDatabase()
    
        configureNavigationBar()
        configureView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard segue.identifier == "filterSegue",
            let destination = segue.destination as? UINavigationController,
            let filterController = destination.topViewController as? FilterViewController else { return }
        
        destination.view.layer.cornerRadius = 8.0
        destination.view.layer.masksToBounds = true
        destination.preferredContentSize = CGSize(width: 0, height: UIScreen.main.bounds.size.height * 2 / 3)
        
        filterController.initialFilter = currentFilter.value
        filterController.completionBlock = { [weak self] in self?.currentFilter.accept($0) }
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
        
        navigationController?.navigationBar.tintColor = Colors.primaryColor
        navigationController?.hero.isEnabled = true
//        navigationController?.hero.navigationAnimationType = .selectBy(presenting: .cover(direction: .left), dismissing: .uncover(direction: .right))
        navigationController?.hero.navigationAnimationType = .selectBy(presenting: .zoom, dismissing: .zoomOut)
    }
    
    private func configureView() {
        
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.separatorStyle = .none
        tableView.rx.modelSelected(QuestionCellModel.self)
            .asDriver()
            .map { DetailViewModel(questionId: $0.id) }
            .drive(onNext: { [unowned self] viewModel in
                guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
                viewController.viewModel = viewModel
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.questions
            .asDriver()
            .map { [QuestionSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        Driver.combineLatest(searchBar.rx.text.asDriver(), currentFilter.asDriver())
            .drive(onNext: { [unowned self] in self.viewModel.loadQuestions(query: $0, filter: $1) })
            .disposed(by: disposeBag)
    
    }
}

