//
//  ViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Hero
import PanModal
import UIKit
import RxCocoa
import RxDataSources
import RxSwift

final class HomeViewController: UIViewController {
    
    typealias QuestionSection = SectionModel<String, QuestionCellModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<QuestionSection>
    
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyMessageLabel: UILabel!
    
    @IBOutlet private weak var tableView: UITableView!
   
    private lazy var filterButton = UIBarButtonItem(image: UIImage(named: "shuffle"), style: .plain, target: self, action: #selector(showRandomQuestion))
    private lazy var shuffleButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(showFilter))
    
    fileprivate var searchBar: UISearchBar!
    
    var viewModel: HomeViewModel!
    
    private let currentFilter = BehaviorRelay<QuestionFilter?>(value: nil)
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
    
        configureNavigationBar()
        configureView()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .titleTextColor()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        tabBarController?.tabBar.tintColor = .titleTextColor()
        
        tableView.reloadData()
        
        searchBar.barStyle = Themer.shared.currentTheme == .light ? .default : .black
        searchBar.keyboardAppearance = Themer.shared.currentTheme == .light ? .light : .dark
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
        
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    
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
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        
        filterButton.tintColor = .appBlueColor()
        shuffleButton.tintColor = .appOrangeColor()
        navigationItem.rightBarButtonItems = [filterButton, shuffleButton]
        
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
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.questions
            .asDriver()
            .map { !$0.isEmpty }
            .drive(emptyStackView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.questions
            .asDriver()
            .map { [QuestionSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
        
        // hack: trigger getters to update drivers
        _ = AppConfigs.shared.hidesSolvedProblems
        _ = AppConfigs.shared.sortOption
        
        Driver.combineLatest(searchBar.rx.text.asDriver(),
                             currentFilter.asDriver(),
                             AppConfigs.shared.hidesSolvedProblemsDriver,
                             AppConfigs.shared.sortOptionDriver)
            .drive(onNext: { [unowned self] in
                self.viewModel.loadQuestions(query: $0,
                                             filter: $1,
                                             onlyUnsolved: $2,
                                             sortOption: $3)
            })
            .disposed(by: disposeBag)
    
    }
    
    @objc private func showRandomQuestion() {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        
        controller.viewModel = viewModel.randomDetailModel()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc private func showFilter() {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "filterNavigationController") as? PannableNavigationController,
            let filterController = navigationController.topViewController as? FilterViewController else { return }
        
        filterController.initialFilter = currentFilter.value
        filterController.completionBlock = { [weak self] in self?.currentFilter.accept($0) }
        
        presentPanModal(navigationController)
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems = []
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems = [filterButton, shuffleButton]
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
