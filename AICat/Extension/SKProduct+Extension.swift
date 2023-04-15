//
//  SKProduct+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/15.
//

import StoreKit

extension SKProduct {
    var locatedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }

    var currencySymbol: String {
        return priceLocale.currencySymbol ?? "$"
    }
}
