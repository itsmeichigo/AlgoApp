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
    
    typealias QuestionSection = SectionModel<String, QuestionCellModel>
    typealias DataSource = RxTableViewSectionedReloadDataSource<QuestionSection>
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: HomeViewModelType!
    private var currentFilter: QuestionFilter?
    private let disposeBag = DisposeBag()
    private lazy var datasource = self.buildDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = HomeViewModel()
        viewModel.loadSeedDatabase()
        viewModel.loadQuestions(filter: currentFilter)
    
        configurePresentable()
    }

    private func buildDataSource() -> DataSource {
        return DataSource(configureCell: { (_, tableView, indexPath, model) -> UITableViewCell in
            let cell: HomeTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configureCell(with: model)
                return cell
        })
    }
    
    private func configurePresentable() {
        
        tableView.separatorStyle = .none
        
        viewModel.questions
            .asDriver()
            .map { [QuestionSection(model: "", items: $0)] }
            .drive(tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
    }
}

