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
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var filterButton: UIBarButtonItem!
    @IBOutlet private weak var shuffleButton: UIBarButtonItem!
    
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
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "filterSegue",
            let destination = segue.destination as? UINavigationController,
            let filterController = destination.topViewController as? FilterViewController {
            destination.view.layer.cornerRadius = 8.0
            destination.view.layer.masksToBounds = true
            
            destination.preferredContentSize = CGSize(width: 0, height: UIScreen.main.bounds.size.height * 2 / 3)
            
            filterController.initialFilter = currentFilter.value
            filterController.completionBlock = { [weak self] in self?.currentFilter.accept($0) }
            
        } else if segue.identifier == "showRandomQuestion",
            let detailController = segue.destination as? DetailViewController {
            detailController.viewModel = viewModel.randomDetailModel()
            detailController.hidesBottomBarWhenPushed = true
        }
        
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.tintColor = .secondaryColor()
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        tableView.reloadData()
        
        searchBar.barStyle = Themer.shared.currentTheme == .light ? .default : .black
        searchBar.keyboardAppearance = Themer.shared.currentTheme == .light ? .light : .dark
        
        view.backgroundColor = .backgroundColor()
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
        
        filterButton.tintColor = .appBlueColor()
        shuffleButton.tintColor = .appOrangeColor()
        
        navigationController?.hero.isEnabled = true
        navigationController?.hero.navigationAnimationType = .selectBy(presenting: .cover(direction: .left), dismissing: .uncover(direction: .right))
    }
    
    private func configureView() {
        
        updateColors()
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.separatorStyle = .none
        tableView.rx.modelSelected(QuestionCellModel.self)
            .asDriver()
            .map { DetailViewModel(questionId: $0.id) }
            .drive(onNext: { [unowned self] model in
                guard let viewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
                viewController.viewModel = model
                viewController.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.questions
            .asDriver()
            .map { [QuestionSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        Driver.combineLatest(searchBar.rx.text.asDriver(), currentFilter.asDriver(), AppConfigs.shared.hidesSolvedProblemsDriver)
            .drive(onNext: { [unowned self] in self.viewModel.loadQuestions(query: $0, filter: $1, onlyUnsolved: $2) })
            .disposed(by: disposeBag)
    
    }
}

