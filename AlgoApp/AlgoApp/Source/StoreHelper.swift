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
    
    var weeklyProduct: Driver<SKProduct?> {
        return weeklyProductRelay.asDriver()
    }
    
    var monthlyProduct: Driver<SKProduct?> {
        return monthlyProductRelay.asDriver()
    }
    
    private let weeklyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    private let monthlyProductRelay = BehaviorRelay<SKProduct?>(value: nil)
    
    private static let weeklyProductId = "com.ichigo.AlgoApp.Weekly"
    private static let monthlyProductId = "com.ichigo.AlgoApp.Monthly"
    
    static func checkPendingTransactions() {
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
        SwiftyStoreKit.retrieveProductsInfo([StoreHelper.weeklyProductId]) { [weak self] results in
            self?.weeklyProductRelay.accept(results.retrievedProducts.first)
        }
        
        SwiftyStoreKit.retrieveProductsInfo([StoreHelper.monthlyProductId]) { [weak self] results in
            self?.monthlyProductRelay.accept(results.retrievedProducts.first)
        }
    }
}
