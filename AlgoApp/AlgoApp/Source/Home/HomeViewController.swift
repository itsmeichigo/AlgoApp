//
//  ViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 2/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

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
   
    private lazy var detailController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "filter"), for: .normal)
        button.tintColor = .appOrangeColor()
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
        button.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
        return button
    }()
    
    private lazy var filterBarButton = UIBarButtonItem(customView: filterButton)
    private lazy var shuffleButton = UIBarButtonItem(image: UIImage(named: "shuffle"), style: .plain, target: self, action: #selector(showRandomQuestion))
    private lazy var settingsButton = UIBarButtonItem(image: UIImage(named: "settings-small"), style: .plain, target: self, action: #selector(showSettings))
    
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
        updateColors()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
        
        splitViewController?.preferredDisplayMode = AppHelper.isIpad ? .allVisible : .primaryOverlay
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appOrangeColor()
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
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        tabBarController?.tabBar.tintColor = .appOrangeColor()
        
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
        
        filterButton.tintColor = .appOrangeColor()
        shuffleButton.tintColor = .appBlueColor()
        settingsButton.tintColor = .appPurpleColor()
        
        if AppHelper.isIpad {
            navigationItem.rightBarButtonItems = [settingsButton, shuffleButton, filterBarButton]
        } else {
            navigationItem.rightBarButtonItems = [shuffleButton, filterBarButton]
        }
        
        let backImage = UIImage(named: "back")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
    }
    
    private func updateDetailController(with questionId: Int, shouldShowDetail: Bool = true) {
        guard let detailController = self.detailController else { return }
        if detailController.viewModel != nil {
            detailController.viewModel.updateDetails(with: questionId)
        } else {
            detailController.viewModel = DetailViewModel(question: questionId)
        }
        
        guard shouldShowDetail else { return }
        
        detailController.codeControllerWillDismiss()
        
        if let controller = detailController.navigationController {
            controller.popToRootViewController(animated: true)
            splitViewController?.showDetailViewController(controller, sender: nil)
        } else {
            let navigationController = UINavigationController(rootViewController: detailController)
            splitViewController?.showDetailViewController(navigationController, sender: nil)
        }
        
    }
    
    private func configureView() {
        
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.separatorStyle = .none
        tableView.rx.modelSelected(QuestionCellModel.self)
            .asDriver()
            .drive(onNext: { [unowned self] question in
                self.searchBar.resignFirstResponder()
                self.updateDetailController(with: question.id)
            })
            .disposed(by: disposeBag)
        
        tableView.rx.willBeginDragging
            .asDriver()
            .drive(onNext: { [unowned self] in
                if self.searchBar.isFirstResponder {
                    self.searchBar.resignFirstResponder()
                }
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
        
        viewModel.questions
            .map { $0.first }
            .filterNil()
            .take(1)
            .subscribe(onNext: { [weak self] question in
                self?.updateDetailController(with: question.id, shouldShowDetail: AppHelper.isIpad)
                self?.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            })
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
        updateDetailController(with: viewModel.randomQuestionId)
    }
    
    @objc private func showFilter() {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "filterNavigationController") as? PannableNavigationController,
            let filterController = navigationController.topViewController as? FilterViewController else { return }
        
        filterController.initialFilter = currentFilter.value
        filterController.completionBlock = { [weak self] in self?.currentFilter.accept($0) }
        
        presentPanModal(navigationController, sourceView: filterButton, sourceRect: CGRect(x: 25, y: 44, width: 0, height: 0))
        
        filterController.popoverPresentationController?.backgroundColor = UIColor.backgroundColor()
    }
    
    @objc private func showSettings() {
        guard let controller = AppHelper.settingsStoryboard.instantiateInitialViewController() else { return }
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.barButtonItem = settingsButton
        present(controller, animated: true, completion: nil)
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems = []
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if AppHelper.isIpad {
            navigationItem.rightBarButtonItems = [settingsButton, shuffleButton, filterBarButton]
        } else {
            navigationItem.rightBarButtonItems = [shuffleButton, filterBarButton]
        }
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
