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
    
    static let premiumProductId = "com.ichigo.AlgoKitty.PremiumPack"
    
    var product: Driver<SKProduct?> {
        return productRelay.asDriver()
    }
    
    let purchaseSuccess = PublishRelay<Void>()
    let purchaseError = PublishRelay<SKError>()
    
    private let productRelay = BehaviorRelay<SKProduct?>(value: nil)
        
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
        SwiftyStoreKit.retrieveProductsInfo([StoreHelper.premiumProductId]) { [weak self] results in
            for product in results.retrievedProducts {
                if product.productIdentifier == StoreHelper.premiumProductId {
                    self?.productRelay.accept(product)
                }
            }
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
    
    static func restorePurchase(completionHandler: ((Bool, SKError?) -> Void)? = nil) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if let failure = results.restoreFailedPurchases.first {
                #if DEBUG
                print("Restore Failed: \(results.restoreFailedPurchases)")
                #endif
                
                completionHandler?(false, failure.0)
            } else if let _ = results.restoredPurchases.first(where: { $0.productId == StoreHelper.premiumProductId }) {
                completionHandler?(true, nil)
            } else {
                completionHandler?(false, nil)
            }
        }
    }
}
