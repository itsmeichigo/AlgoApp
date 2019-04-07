//
//  StoreHelper.swift
//  AlgoApp
//
//  Created by Huong Do on 3/23/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import StoreKit
import SwiftyStoreKit

final class StoreHelper {
    
    static let monthlyProductId = "com.ichigo.AlgoDaily.monthly"
    static let yearlyProductId = "com.ichigo.AlgoDaily.Yearly"
    
    var products: Driver<[SKProduct]> {
        return productsRelay.asDriver()
    }
    
    var monthlyProduct: Driver<SKProduct?> {
        return monthlyProductRelay.asDriver()
    }
    
    var yearlyProduct: Driver<SKProduct?> {
        return yearlyProductRelay.asDriver()
    }
    
    let purchaseSuccess = PublishRelay<Void>()
    let purchaseError = PublishRelay<SKError>()
    
    private let monthlyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    private let yearlyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    private let productsRelay = BehaviorRelay<[SKProduct]>(value: [])
    
    private static let sharedSecret = "416fafcd56174d3b9d4174ebab9b5512"
    
    static func checkPendingTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    AppConfigs.shared.isPremium = true
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
    }
    
    func fetchProductsInfo() {
        SwiftyStoreKit.retrieveProductsInfo([StoreHelper.monthlyProductId, StoreHelper.yearlyProductId]) { [weak self] results in
            for product in results.retrievedProducts {
                if product.productIdentifier == StoreHelper.monthlyProductId {
                    self?.monthlyProductRelay.accept(product)
                } else if product.productIdentifier == StoreHelper.yearlyProductId {
                    self?.yearlyProductRelay.accept(product)
                }
            }
            self?.productsRelay.accept(Array(results.retrievedProducts))
        }
    }
    
    func purchase(product: SKProduct) {
        SwiftyStoreKit.purchaseProduct(product) { [weak self] result in
            switch result {
            case .success(let product):
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                self?.purchaseSuccess.accept(())
            case .error(let error):
                self?.purchaseError.accept(error)
            }
        }
    }
    
    static func verifySubscription(completionHandler: ((Bool) -> Void)? = nil) {
        // FIXME: update service type here!!!
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            var purchased = false
            
            switch result {
            case .success(let receipt):
                // Verify the purchase of weekly subscription
                let purchaseWeeklyResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: StoreHelper.monthlyProductId,
                    inReceipt: receipt)
                
                switch purchaseWeeklyResult {
                case .purchased:
                    purchased = true
                default:
                    break
                }
                
                // Verify the purchase of monthly subscription
                let purchaseMonthlyResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: StoreHelper.yearlyProductId,
                    inReceipt: receipt)
                
                switch purchaseMonthlyResult {
                case .purchased:
                    purchased = true
                default:
                    break
                }
                
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
            
            completionHandler?(purchased)
        }
    }
}
