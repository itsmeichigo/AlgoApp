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
    
    var products: Driver<[SKProduct]> {
        return productsRelay.asDriver()
    }
    
    var weeklyProduct: Driver<SKProduct?> {
        return weeklyProductRelay.asDriver()
    }
    
    var monthlyProduct: Driver<SKProduct?> {
        return monthlyProductRelay.asDriver()
    }
    
    var verificationResult: Driver<Bool> {
        return Driver.combineLatest(purchasedWeeklyProductRelay.asDriver(), purchasedMonthlyProductRelay.asDriver())
            .map { $0.0 && $0.1 }
    }
    
    let purchaseSuccess = PublishRelay<Void>()
    let purchaseError = PublishRelay<SKError>()
    
    private let weeklyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    private let monthlyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    private let productsRelay = BehaviorRelay<[SKProduct]>(value: [])
    
    private let purchasedWeeklyProductRelay = BehaviorRelay<Bool>(value: false)
    private let purchasedMonthlyProductRelay = BehaviorRelay<Bool>(value: false)
    
    static let weeklyProductId = "com.ichigo.AlgoApp.Weekly"
    static let monthlyProductId = "com.ichigo.AlgoApp.Monthly"
    
    func checkPendingTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
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
        SwiftyStoreKit.retrieveProductsInfo([StoreHelper.weeklyProductId, StoreHelper.monthlyProductId]) { [weak self] results in
            for product in results.retrievedProducts {
                if product.productIdentifier == StoreHelper.weeklyProductId {
                    self?.weeklyProductRelay.accept(product)
                } else if product.productIdentifier == StoreHelper.monthlyProductId {
                    self?.monthlyProductRelay.accept(product)
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
    
    func verifySubscription() {
        let appleValidator = AppleReceiptValidator(service: .sandbox)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [weak self] result in
            switch result {
            case .success(let receipt):
                // Verify the purchase of weekly subscription
                let purchaseWeeklyResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: StoreHelper.weeklyProductId,
                    inReceipt: receipt)
                
                switch purchaseWeeklyResult {
                case .purchased:
                    self?.purchasedWeeklyProductRelay.accept(true)
                default:
                    break
                }
                
                // Verify the purchase of monthly subscription
                let purchaseMonthlyResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable,
                    productId: StoreHelper.monthlyProductId,
                    inReceipt: receipt)
                
                switch purchaseMonthlyResult {
                case .purchased:
                    self?.purchasedMonthlyProductRelay.accept(true)
                default:
                    break
                }
                
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
}
