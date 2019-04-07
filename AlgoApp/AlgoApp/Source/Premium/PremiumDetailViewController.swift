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

enum LegalType {
    case privacyPolicy
    case terms
    
    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .terms: return "Terms"
        }
    }
    
    var link: String {
        switch self {
        case .privacyPolicy: return "https://gist.github.com/16bitsapps/0825806307a34381b30e4f7f51327bf1"
        case .terms: return "https://gist.github.com/16bitsapps/abbb4b23d1e2cfe054fc947ede565266"
        }
    }
    
    var contentSelector: String {
        switch self {
        case .privacyPolicy: return "#file-algodaily-policy-md"
        case .terms: return "#file-algodaily-terms-md"
        }
    }
}

class PremiumDetailViewController: UIViewController {

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet private weak var dismissButton: UIBarButtonItem!
    
    @IBOutlet private weak var monthlyProductView: UIView!
    @IBOutlet private weak var monthlyProductNameLabel: UILabel!
    @IBOutlet private weak var monthlyProductPriceLabel: UILabel!
    @IBOutlet private weak var monthlyProductDescriptionLabel: UILabel!
    @IBOutlet private weak var monthlyProductButton: UIButton!
    
    @IBOutlet private weak var yearlyProductView: UIView!
    @IBOutlet private weak var yearlyProductNameLabel: UILabel!
    @IBOutlet private weak var yearlyProductPriceLabel: UILabel!
    @IBOutlet private weak var yearlyProductDescriptionLabel: UILabel!
    @IBOutlet private weak var yearlyProductButton: UIButton!
    
    @IBOutlet weak var loadingProductsView: UIView!
    
    @IBOutlet weak var termsTextView: UITextView!
    
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
        configureTermsTextView()
        configureButtons()
        configureStore()
        
        store.fetchProductsInfo()
        SVProgressHUD.configure()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
        super.viewWillDisappear(animated)
    }

    private func configureColors() {
        
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        view.backgroundColor = .backgroundColor()
        
        pageControl.currentPageIndicatorTintColor = .appRedColor()
        pageControl.pageIndicatorTintColor = UIColor.appRedColor().withAlphaComponent(0.2)
        pageControl.numberOfPages = PremiumDetailType.allCases.count
        
        continueButton.isEnabled = false
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .subtitleTextColor()
        continueButton.layer.cornerRadius = 8.0
        
        [monthlyProductView, yearlyProductView].forEach { view in
            view?.layer.cornerRadius = 8.0
            view?.dropCardShadow()
            view?.layer.borderColor = UIColor.appRedColor().cgColor
            view?.layer.borderWidth = 0.0
        }
        
        dismissButton.tintColor = .subtitleTextColor()
        
        purchasedLabel.textColor = .appRedColor()
        restoreButton.tintColor = .appRedColor()
        
        confettiView.type = .mixed
        confettiView.isUserInteractionEnabled = false
        view.addSubview(confettiView)
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
                StoreHelper.verifySubscription { [weak self] purchased in
                    SVProgressHUD.dismiss()
                    
                    self?.showAlert(forVerificationResult: purchased)
                }
            })
            .disposed(by: disposeBag)
        
        monthlyProductButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.monthlyProductButton.isSelected = true
                self?.monthlyProductView.layer.borderWidth = 3.0
                self?.yearlyProductView.layer.borderWidth = 0.0
                self?.yearlyProductButton.isSelected = false
            })
            .disposed(by: disposeBag)
        
        yearlyProductButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] in
                self?.monthlyProductButton.isSelected = false
                self?.monthlyProductView.layer.borderWidth = 0.0
                self?.yearlyProductView.layer.borderWidth = 3.0
                self?.yearlyProductButton.isSelected = true
            })
            .disposed(by: disposeBag)
        
        Driver.merge(monthlyProductButton.rx.tap.asDriver(), yearlyProductButton.rx.tap.asDriver())
            .map { true }
            .do(onNext: { [weak self] _ in
                self?.continueButton.backgroundColor = .appRedColor()
            })
            .drive(continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        continueButton.rx.tap.asDriver()
            .withLatestFrom(store.products)
            .drive(onNext: { [weak self] products in
                guard let self = self else { return }
                if self.monthlyProductButton.isSelected == true,
                    let product = products.first(where: { $0.productIdentifier == StoreHelper.monthlyProductId }) {
                    self.store.purchase(product: product)
                } else if self.yearlyProductButton.isSelected == true,
                    let product = products.first(where: { $0.productIdentifier == StoreHelper.yearlyProductId }) {
                    self.store.purchase(product: product)
                }
                
                SVProgressHUD.show()
            })
            .disposed(by: disposeBag)
    }
    
    private func configureStore() {
        store.products
            .map { !$0.isEmpty }
            .drive(onNext: { [weak self] in
                self?.loadingProductsView.isHidden = $0
                self?.monthlyProductView.isHidden = !$0
                self?.yearlyProductView.isHidden = !$0
            })
            .disposed(by: disposeBag)
        
        store.monthlyProduct
            .map { $0?.localizedTitle }
            .drive(monthlyProductNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.monthlyProduct
            .map { $0?.localizedPrice }
            .drive(monthlyProductPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.monthlyProduct
            .map { $0?.localizedDescription }
            .drive(monthlyProductDescriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.yearlyProduct
            .map { $0?.localizedTitle }
            .drive(yearlyProductNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.yearlyProduct
            .map { $0?.localizedPrice }
            .drive(yearlyProductPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.yearlyProduct
            .map { $0?.localizedDescription }
            .drive(yearlyProductDescriptionLabel.rx.text)
            .disposed(by: disposeBag)
        
        store.purchaseSuccess
            .asDriver(onErrorDriveWith: .never())
            .drive(onNext: { [weak self] in
                SVProgressHUD.dismiss()
                AppConfigs.shared.isPremium = true
                self?.confettiView.startConfetti()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    self?.confettiView.stopConfetti()
                    self?.dismiss(animated: true, completion: nil)
                })
                
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
    
    private func configureTermsTextView() {
        let string = "Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase. By tapping \"Start Subscription\" you agree to AlgoDaily's Privacy Policy and Terms."
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(.foregroundColor, value: UIColor.subtitleTextColor(), range: NSRange(location: 0, length: string.count))
        
        if let range = string.range(of: LegalType.privacyPolicy.title) {
            attributedString.addAttribute(.link, value: LegalType.privacyPolicy.link, range: NSRange(range, in: string))
        }
        
        if let range = string.range(of: LegalType.terms.title) {
            attributedString.addAttribute(.link, value: LegalType.terms.link, range: NSRange(range, in: string))
        }
        
        termsTextView.attributedText = attributedString
        termsTextView.delegate = self
    }
    
    private func configureDatasource() -> Datasource {
        return RxCollectionViewSectionedReloadDataSource<Section>(configureCell: { (_, collectionView, indexPath, model) -> UICollectionViewCell in
            let cell: PremiumDetailCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.configureCell(model: model)
            return cell
        })
    }
    
    private func showAlert(forVerificationResult purchased: Bool) {
        let message = purchased ? "Voila 🎉 Your subscription has been updated!" : "Uh oh 😕 You haven't purchased any subscription."
        
        let alert = UIAlertController(title: "Restore Subscription", message: message, preferredStyle: .alert)
        
        if purchased {
            let action = UIAlertAction(title: "Thanks!", style: .default) { [unowned self] _ in self.dismiss(animated: true, completion: nil) }
            alert.addAction(action)
        } else {
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
        }
        
        present(alert, animated: true, completion: nil)
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

extension PremiumDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let type: LegalType = URL.absoluteString == LegalType.privacyPolicy.link ? .privacyPolicy : .terms
        showWebpage(url: URL, title: type.title, contentSelector: type.contentSelector)
        return false
    }
    
    private func showWebpage(url: URL, title: String = "", contentSelector: String?) {
        let viewController = WebViewController()
        viewController.url = url
        viewController.title = title
        viewController.contentSelector = contentSelector
        navigationController?.pushViewController(viewController, animated: true)
    }
}
