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
    
    private lazy var badgeIcon: UILabel = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = .appRedColor()
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "filter"), for: .normal)
        button.tintColor = .appOrangeColor()
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
        button.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
        button.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints({ maker in
            maker.height.equalTo(20)
            maker.top.equalToSuperview().offset(-10)
            maker.leading.equalToSuperview().offset(10)
            maker.width.greaterThanOrEqualTo(20)
        })
        return button
    }()
    
    private lazy var filterBarButton = UIBarButtonItem(customView: filterButton)
    private lazy var shuffleButton = UIBarButtonItem(image: UIImage(named: "shuffle"), style: .plain, target: self, action: #selector(showRandomQuestion))
    
    fileprivate var searchBar: UISearchBar!
    
    var viewModel: HomeViewModel!
    
    private let currentFilter = BehaviorRelay<QuestionFilter?>(value: nil)
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    private var firstAppear = true
    
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
        
        if AppHelper.isIpad {
            splitViewController?.preferredDisplayMode = .allVisible
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appOrangeColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if splitViewController?.isRegularWidth == true && firstAppear {
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            firstAppear = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if splitViewController?.isRegularWidth == true &&
            splitViewController?.viewControllers.count == 1 {
            updateDetailController(with: viewModel.questions.value[0].id)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    func updateDetailController(with questionId: Int, shouldShowNote: Bool = false, shouldShowDetail: Bool = true) {
        guard let detailController = self.detailController else { return }
        if detailController.viewModel != nil {
            detailController.viewModel.updateDetails(with: questionId)
        } else {
            detailController.viewModel = DetailViewModel(question: questionId)
        }
        
        guard shouldShowDetail else { return }
        
        detailController.shouldShowNote = shouldShowNote
        
        if let controller = detailController.navigationController {
            controller.popToRootViewController(animated: true)
            splitViewController?.showDetailViewController(controller, sender: nil)
        } else {
            let navigationController = UINavigationController(rootViewController: detailController)
            splitViewController?.showDetailViewController(navigationController, sender: nil)
        }
        
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
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
        
        navigationItem.rightBarButtonItems = [shuffleButton, filterBarButton]
        
        let backImage = UIImage(named: "back")
        navigationController?.navigationBar.backIndicatorImage = backImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
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
                guard let self = self else { return }
                self.updateDetailController(with: question.id, shouldShowDetail: self.splitViewController?.isRegularWidth == true)
                self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            })
            .disposed(by: disposeBag)
        
        // hack: trigger getters to update drivers
        _ = AppConfigs.shared.hidesSolvedProblems
        _ = AppConfigs.shared.sortOption
        
        currentFilter.asDriver()
            .map { $0?.allFilters.count ?? 0 }
            .drive(onNext: { [weak self] in
                self?.badgeIcon.text = "\($0)"
                self?.badgeIcon.isHidden = $0 == 0
            })
            .disposed(by: disposeBag)
        
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
        guard let id = viewModel.randomQuestionId else { return }
        updateDetailController(with: id)
    }
    
    @objc private func showFilter() {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "filterNavigationController") as? PannableNavigationController,
            let filterController = navigationController.topViewController as? FilterViewController else { return }
        
        filterController.initialFilter = currentFilter.value
        filterController.completionBlock = { [weak self] in self?.currentFilter.accept($0) }
        
        presentPanModal(navigationController, sourceView: filterButton, sourceRect: CGRect(x: 25, y: 44, width: 0, height: 0))
        
        filterController.popoverPresentationController?.backgroundColor = UIColor.backgroundColor()
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems = []
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationItem.rightBarButtonItems = [shuffleButton, filterBarButton]
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
