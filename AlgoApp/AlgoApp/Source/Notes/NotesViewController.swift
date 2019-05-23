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
        
        AppConfigs.shared.currentThemeDriver
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureCollectionViewLayoutItemSize()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let previousTraitCollection = previousTraitCollection,
            previousTraitCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            updateCountLabel()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppConfigs.shared.currentTheme == .light ? .default : .lightContent
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = AppConfigs.shared.currentTheme == .light ? .backgroundColor() : .primaryColor()
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
            .do(onNext: { [weak self] _ in self?.updateCountLabel() })
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
                    self?.showDeleteAlert(for: model)
                })
                .disposed(by: cell.disposeBag)
            
            cell.editButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.showQuestion(id: model.questionId)
                })
                .disposed(by: cell.disposeBag)
            
            cell.shareButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.shareNote(content: model.content, sourceView: cell.shareButton, sourceRect: CGRect(x: cell.shareButton.frame.width / 2, y: cell.shareButton.frame.height / 2, width: 0, height: 0))
                })
                .disposed(by: cell.disposeBag)
            
            return cell
        })
    }
    
    private func shareNote(content: String, sourceView: UIView? = nil, sourceRect: CGRect = .zero) {
        let controller = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = sourceView
        controller.popoverPresentationController?.sourceRect = sourceRect
        present(controller, animated: true, completion: nil)
        
        controller.popoverPresentationController?.backgroundColor = .backgroundColor()
    }

    
    private func showDeleteAlert(for note: NoteCellModel) {
        let alert = UIAlertController(title: "Delete Note", message: "Are you sure you want to remove this note?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Yes", style: .default) { [unowned self] _ in
            self.viewModel.deleteNote(note)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func showQuestion(id: Int) {
        guard let splitViewController = tabBarController?.viewControllers?.first as? UISplitViewController,
            let navigationController = splitViewController.viewControllers.first as? UINavigationController else { return }
        
        if let presentedController = splitViewController.presentedViewController {
            presentedController.dismiss(animated: false, completion: nil)
        }
        
        if let homeViewController = navigationController.topViewController as? HomeViewController {
            homeViewController.updateDetailController(with: id, shouldShowNote: true)
        } else if let detailNavigationController = navigationController.topViewController as? UINavigationController  {
            detailNavigationController.popToRootViewController(animated: false)
            if let detailController = detailNavigationController.topViewController as? DetailViewController {
                detailController.viewModel.updateDetails(with: id)
                detailController.shouldShowNote = true
            }
        }
        
        tabBarController?.selectedIndex = 0
    }
    
    // MARK: - collection view magic
    private var indexOfCellBeforeDragging = 0
    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }()
    
    private func calculateSectionInset() -> CGFloat {
        return AppHelper.isIpad ? 48 : 16
    }
    
    private func configureCollectionViewLayoutItemSize() {
        let inset: CGFloat = calculateSectionInset()
        let verticalInset = AppHelper.isIpad ? inset / 2 : 0
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: verticalInset, left: inset, bottom: verticalInset, right: inset)
        
        collectionViewFlowLayout.itemSize = CGSize(width: collectionView.frame.width
            - inset * 2, height: collectionView.frame.height - verticalInset * 2)
    }
    
    private func indexOfMajorCell() -> Int {
        let itemWidth = collectionViewFlowLayout.itemSize.width
        let proportionalOffset = collectionView.collectionViewLayout.collectionView!.contentOffset.x / itemWidth
        let index = Int(round(proportionalOffset))
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let safeIndex = max(0, min(numberOfItems - 1, index))
        return safeIndex
    }
    
    private func updateCountLabel() {
        pageCountLabel.text = isCompactHeight ? "" : "Note \(indexOfMajorCell() + 1) of \(viewModel.notes.value.count)"
    }
}

extension NotesViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexOfCellBeforeDragging = indexOfMajorCell()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCountLabel()
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
