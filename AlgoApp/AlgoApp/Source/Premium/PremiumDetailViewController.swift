//
//  PremiumDetailViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/24/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import StoreKit
import SVProgressHUD

enum PremiumDetailType: CaseIterable {
    case `default`
    case alarm
    case code
    case darkMode
    
    var logoImage: UIImage? {
        switch self {
        case .default: return UIImage(named: "premium")
        case .alarm: return UIImage(named: "alarm-clock")
        case .code: return UIImage(named: "code")
        case .darkMode: return UIImage(named: "moon")
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "Unlock Premium to get access \nto all features"
        case .alarm:
            return "Set reminders to practice \ncoding problems everyday"
        case .code:
            return "Quickly save code snippets \nwith proper syntax highlight"
        case .darkMode:
            return "Switch app to Dark Mode \nas it's a cool and hip thing to do"
        }
    }
}

class PremiumDetailViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionViewTopSpace: NSLayoutConstraint!
    
    @IBOutlet weak private var purchaseButton: UIButton!
    @IBOutlet private weak var dismissButton: UIBarButtonItem!
    
    @IBOutlet weak var loadingProductsView: UIView!
    
    @IBOutlet weak var purchasedLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    
    typealias Section = SectionModel<String, PremiumDetailType>
    typealias Datasource = RxCollectionViewSectionedReloadDataSource<Section>
    
    private let disposeBag = DisposeBag()
    private lazy var datasource = configureDatasource()
    
    private let store = StoreHelper()
    private let confettiView = ConfettiView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureColors()
        configureCollectionView()
        configureButtons()
        configureStore()
        
        store.fetchProductsInfo()
        SVProgressHUD.configure()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if restoreButton.frame.maxY < scrollView.frame.maxY {
            let margin = (scrollView.frame.maxY - restoreButton.frame.maxY) / 2
            collectionViewTopSpace.constant = margin - 20
        } else {
            collectionViewTopSpace.constant = 0
        }
    }

    private func configureColors() {
        
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .backgroundColor()
        
        pageControl.currentPageIndicatorTintColor = .appRedColor()
        pageControl.pageIndicatorTintColor = UIColor.appRedColor().withAlphaComponent(0.2)
        pageControl.numberOfPages = PremiumDetailType.allCases.count
        
        purchaseButton.isHidden = true
        purchaseButton.setTitleColor(.white, for: .normal)
        purchaseButton.backgroundColor = .appRedColor()
        purchaseButton.layer.cornerRadius = 8.0
        
        dismissButton.tintColor = .subtitleTextColor()
        
        purchasedLabel.textColor = .subtitleTextColor()
        restoreButton.tintColor = .appRedColor()
        
        confettiView.type = .mixed
        confettiView.isUserInteractionEnabled = false
        UIApplication.shared.keyWindow?.addSubview(confettiView)
        confettiView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
    
    private func configureCollectionView() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let screenWidth = UIScreen.main.bounds.width
            layout.itemSize = CGSize(width: screenWidth, height: collectionView.frame.height)
        }
        
        collectionView.delegate = self
        
        Driver.just(PremiumDetailType.allCases)
            .map { [Section(model: "", items: $0)] }
            .drive(collectionView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)
    }
    
    private func configureButtons() {
        dismissButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        restoreButton.rx.tap
            .subscribe(onNext: {
                SVProgressHUD.show()
                StoreHelper.restorePurchase() { [weak self] (purchased, error) in
                    SVProgressHUD.dismiss()
                    
                    AppConfigs.shared.isPremium = purchased
                    self?.showAlert(forResult: purchased, error: error)
                }
            })
            .disposed(by: disposeBag)
        
        purchaseButton.rx.tap.asDriver()
            .withLatestFrom(store.product)
            .drive(onNext: { [weak self] product in
                guard let self = self, let product = product else { return }
                self.store.purchase(product: product)
                SVProgressHUD.show()
            })
            .disposed(by: disposeBag)
    }
    
    private func configureStore() {
        store.product
            .map { $0 != nil }
            .drive(onNext: { [weak self] in
                self?.loadingProductsView.isHidden = $0
                self?.purchaseButton.isHidden = !$0
            })
            .disposed(by: disposeBag)
        
        store.product
            .map { $0?.localizedPrice }
            .filterNil()
            .map { "Purchase with \($0)" }
            .drive(onNext: { [weak self] in self?.purchaseButton.setTitle($0, for: .normal) })
            .disposed(by: disposeBag)
        
        store.purchaseSuccess
            .asDriver(onErrorDriveWith: .never())
            .drive(onNext: { [weak self] in
                SVProgressHUD.dismiss()
                AppConfigs.shared.isPremium = true
                self?.showerConfetti()
            })
            .disposed(by: disposeBag)
        
        store.purchaseError
            .asDriver(onErrorDriveWith: .never())
            .drive(onNext: { [weak self] in
                SVProgressHUD.dismiss()
                self?.showAlert(for: $0)
            })
            .disposed(by: disposeBag)
    }
    
    private func showerConfetti() {
        confettiView.startConfetti()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.confettiView.stopConfetti()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    private func configureDatasource() -> Datasource {
        return RxCollectionViewSectionedReloadDataSource<Section>(configureCell: { (_, collectionView, indexPath, model) -> UICollectionViewCell in
            let cell: PremiumDetailCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configureCell(model: model)
            return cell
        })
    }
    
    private func showAlert(forResult purchased: Bool, error: SKError?) {
        let message = error != nil ? (error?.localizedDescription ?? "") : (purchased ? "Voila 🎉 You have unlocked Premium!" : "Uh oh 😕 You haven't purchased Premium.")
        
        let alert = UIAlertController(title: "Restore Purchase", message: message, preferredStyle: .alert)
        
        if purchased {
            let action = UIAlertAction(title: "Thanks!", style: .default) { [unowned self] _ in self.dismiss(animated: true, completion: nil) }
            alert.addAction(action)
        } else {
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
        }
        
        present(alert, animated: true) {
            if purchased { self.showerConfetti() }
        }
    }
    
    private func showAlert(for error: SKError) {
        var message: String?
        
        switch error.code {
        case .clientInvalid:
            message = "The payment was denied. Please contact support."
        case .paymentCancelled:
            print("Payment was cancelled")
            break
        case .paymentInvalid:
            message = "The selected product was invalid. Please try again."
        case .paymentNotAllowed:
            message = "The device is not allowed to make the payment. Please contact support."
        case .storeProductNotAvailable:
            print("The product is not available in the current storefront. Please contact support.")
        case .cloudServicePermissionDenied:
            print("Access to cloud service information is not allowed. Please contact support.")
        case .cloudServiceNetworkConnectionFailed:
            print("Could not connect to the network. Please try again later.")
        case .cloudServiceRevoked:
            print("Permission to use this cloud service has been revoked.")
        default:
            message = "Unknown error. Please contact support."
        }

        if let message = message {
            let alertController = UIAlertController(title: "Purchase Failed", message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Try again", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension PremiumDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
       pageControl.currentPage = indexPath.item
    }
    
}
