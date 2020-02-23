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
    
    @IBOutlet weak var notificationContainerView: UIView!
    @IBOutlet weak var notificationView: UIView!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var notificationSubtitleLabel: UILabel!
    @IBOutlet weak var notificationTitleLabel: UILabel!
    @IBOutlet weak var notificationDismissButton: UIButton!
   
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
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 44)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 5)
        button.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
        button.addSubview(badgeIcon)
        badgeIcon.snp.makeConstraints({ maker in
            maker.height.equalTo(20)
            maker.top.equalToSuperview().offset(-10)
            maker.leading.equalToSuperview().offset(25)
            maker.width.greaterThanOrEqualTo(20)
        })
        return button
    }()
    
    private lazy var filterBarButton = UIBarButtonItem(customView: filterButton)
    private lazy var shuffleButton = UIBarButtonItem(image: UIImage(named: "shuffle"), style: .plain, target: self, action: #selector(showRandomQuestion))
    
    fileprivate var searchBar: UISearchBar!
    
    var viewModel: HomeViewModel!
    
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    private var firstAppear = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
    
        configureNavigationBar()
        configureView()
        updateColors()
        
        AppConfigs.shared.currentThemeDriver
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
            updateInitialFilter()
            tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            firstAppear = false
        } else if firstAppear {
            updateInitialFilter()
            firstAppear = false
        }
        
        showLastOpenedQuestion()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // set detail controller on iphone when first rotated
        if !AppHelper.isIpad && splitViewController?.isRegularWidth == true &&
            splitViewController?.viewControllers.count == 1 {
            updateDetailController(with: viewModel.questions.value[0].id)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.resignFirstResponder()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppConfigs.shared.currentTheme == .light ? .default : .lightContent
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
}

private extension HomeViewController {
    func showLastOpenedQuestion() {
        let id = AppConfigs.shared.lastOpenedQuestionId
        guard let question = viewModel.getLastQuestion(id: id) else {
            UIView.animate(withDuration: 0.3) {
                self.notificationContainerView.isHidden = true
            }
            return
        }
        
        notificationTitleLabel.text = [question.emoji ?? "", question.title].joined(separator: "  ")
        
        UIView.animate(withDuration: 0.3) {
            self.notificationContainerView.isHidden = false
        }
    }
    
    func updateInitialFilter() {
        let filter = AppConfigs.shared.currentFilter
        AppConfigs.shared.currentFilter = filter
    }
    
    func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = AppConfigs.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        tableView.reloadData()
        
        searchBar.barStyle = AppConfigs.shared.currentTheme == .light ? .default : .black
        searchBar.keyboardAppearance = AppConfigs.shared.currentTheme == .light ? .light : .dark
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
                
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    func buildDataSource() -> DataSource {
        return DataSource(configureCell: { (_, tableView, indexPath, model) -> UITableViewCell in
            let cell: HomeTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configureCell(with: model)
            return cell
        })
    }
    
    func configureNavigationBar() {
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
    
    func configureView() {
        
        notificationView.layer.cornerRadius = 8
        notificationView.dropCardShadow()
        notificationDismissButton.rx.tap
            .subscribe(onNext: { [weak self] in
                UIView.animate(withDuration: 0.3, animations: {
                    self?.notificationContainerView.isHidden = true
                }, completion: { _ in
                    AppConfigs.shared.lastOpenedQuestionId = -1
                })
            })
            .disposed(by: disposeBag)
        
        notificationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.updateDetailController(with: AppConfigs.shared.lastOpenedQuestionId)
                self?.notificationDismissButton.sendActions(for: .touchUpInside)
            })
            .disposed(by: disposeBag)
        
        UIApplication.shared.rx.applicationWillTerminate
            .subscribe(onNext: { _ in
                AppConfigs.shared.lastOpenedQuestionId = -1
            })
            .disposed(by: disposeBag)
        
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
        _ = AppConfigs.shared.sortOption
        
        AppConfigs.shared.currentFilterDriver
            .map { $0.allFilters.count }
            .drive(onNext: { [weak self] in
                self?.badgeIcon.text = "\($0)"
                self?.badgeIcon.isHidden = $0 == 0
            })
            .disposed(by: disposeBag)
        
        Driver.combineLatest(searchBar.rx.text.asDriver(),
                             AppConfigs.shared.currentFilterDriver,
                             AppConfigs.shared.sortOptionDriver)
            .drive(onNext: { [unowned self] in
                self.viewModel.loadQuestions(query: $0,
                                             filter: $1,
                                             sortOption: $2)
            })
            .disposed(by: disposeBag)
        
        UIApplication.shared.rx.applicationDidBecomeActive
            .startWith(.active)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if #available(iOS 13.0, *) {
                    switch self.traitCollection.userInterfaceStyle {
                    case .light, .unspecified:
                        AppConfigs.shared.currentTheme = .light
                    case .dark:
                        AppConfigs.shared.currentTheme = .dark
                    @unknown default:
                        AppConfigs.shared.currentTheme = .light
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func showRandomQuestion() {
        guard let id = viewModel.randomQuestionId else {
            let alertController = UIAlertController(title: "Oops", message: "No problem found with your current filter", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(alertAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        updateDetailController(with: id)
    }
    
    @objc private func showFilter() {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "filterNavigationController") as? PannableNavigationController,
            let filterController = navigationController.topViewController as? FilterViewController else { return }
        
        filterController.initialFilter = AppConfigs.shared.currentFilter
        filterController.completionBlock = { AppConfigs.shared.currentFilter = $0 }
        
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
