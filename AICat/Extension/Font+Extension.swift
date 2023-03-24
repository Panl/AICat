//
//  Font+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/22.
//

import SwiftUI

let manropePath = Bundle.main.path(forResource: "Manrpoe", ofType: "ttf")

extension Font {
    static func manrope(size: CGFloat, weight: Font.Weight) -> Font {
        Font.custom("Manrope", size: size).weight(weight)
    }
}
