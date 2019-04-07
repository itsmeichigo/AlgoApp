//
//  NotesViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 4/6/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class NotesViewController: UIViewController {

    typealias Section = AnimatableSectionModel<String, NoteCellModel>
    typealias Datasource = RxCollectionViewSectionedAnimatedDataSource<Section>
    
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyMessageLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageCountLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    private let viewModel = NotesViewModel()
    private lazy var datasource = buildDatasource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        configureCollectionView()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.updateColors()
            })
            .disposed(by: disposeBag)
        
        viewModel.loadNotes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.tintColor = .appBlueColor()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = Themer.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        emptyTitleLabel.textColor = .subtitleTextColor()
        emptyMessageLabel.textColor = .subtitleTextColor()
        pageCountLabel.textColor = .subtitleTextColor()
        
        view.backgroundColor = .backgroundColor()
        
        collectionView.backgroundColor = .backgroundColor()
        collectionView.reloadData()
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func configureView() {
        viewModel.notes.asDriver()
            .map { $0.isEmpty }
            .drive(collectionView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.notes.asDriver()
            .do(onNext: { [weak self] in
                self?.updateCountLabel(total: $0.count)
            })
            .map { $0.isEmpty }
            .drive(pageCountLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func configureCollectionView() {

        configureCollectionViewLayoutItemSize()
        collectionView.delegate = self
        
        viewModel.notes.asDriver()
            .map { [Section(model: "", items: $0)] }
            .drive(collectionView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
    }
    
    private func buildDatasource() -> Datasource {
        return Datasource(configureCell: { (_, collectionView, indexPath, model) -> UICollectionViewCell in
            let cell: NoteCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configureCell(model: model)
            cell.deleteButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.showDeleteAlert(for: model.id)
                })
                .disposed(by: cell.disposeBag)
            
            cell.editButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.showQuestion(id: model.questionId)
                })
                .disposed(by: cell.disposeBag)
            
            return cell
        })
    }
    
    private func showDeleteAlert(for noteId: String) {
        let alert = UIAlertController(title: "Delete Note", message: "Are you sure you want to remove this note?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes", style: .default) { [unowned self] _ in
            self.viewModel.deleteNote(id: noteId)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showQuestion(id: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        
        viewController.viewModel = DetailViewModel(questionId: id)
        viewController.shouldShowNote = true
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    
    // MARK: - collection view magic
    private var indexOfCellBeforeDragging = 0
    private var collectionViewFlowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    private func calculateSectionInset() -> CGFloat {
        return 16
    }
    
    private func configureCollectionViewLayoutItemSize() {
        let inset: CGFloat = calculateSectionInset()
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
        collectionViewFlowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width - inset * 2, height: collectionView.frame.height)
    }
    
    private func indexOfMajorCell() -> Int {
        let itemWidth = collectionViewFlowLayout.itemSize.width
        let proportionalOffset = collectionView.collectionViewLayout.collectionView!.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let safeIndex = max(0, min(numberOfItems - 1, index))
        return safeIndex
    }
    
    private func updateCountLabel(total: Int) {
        pageCountLabel.text = "Note \(indexOfMajorCell() + 1) of \(total)"
    }
}

extension NotesViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexOfCellBeforeDragging = indexOfMajorCell()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCountLabel(total: collectionView.numberOfItems(inSection: 0))
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Stop scrollView sliding:
        targetContentOffset.pointee = scrollView.contentOffset
        
        // calculate where scrollView should snap to:
        let indexOfMajorCell = self.indexOfMajorCell()
        
        // calculate conditions:
        let dataSourceCount = collectionView.numberOfItems(inSection: 0)
        let swipeVelocityThreshold: CGFloat = 0.5 // after some trail and error
        let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < dataSourceCount && velocity.x > swipeVelocityThreshold
        let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
        let majorCellIsTheCellBeforeDragging = indexOfMajorCell == indexOfCellBeforeDragging
        let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)
        
        if didUseSwipeToSkipCell {
            
            let snapToIndex = indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
            let toValue = collectionViewFlowLayout.itemSize.width * CGFloat(snapToIndex)
            
            // Damping equal 1 => no oscillations => decay animation:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity.x, options: .allowUserInteraction, animations: {
                scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                scrollView.layoutIfNeeded()
            }, completion: nil)
            
        } else {
            // This is a much better way to scroll to a cell:
            let indexPath = IndexPath(row: indexOfMajorCell, section: 0)
            collectionView.collectionViewLayout.collectionView!.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}