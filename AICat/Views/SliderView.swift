//
//  SliderView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/7.
//

import SwiftUI

struct SliderView: View {
    @Binding var value: Double

    var color: Color = .gray
    var sliderRange: ClosedRange<Double> = 0...2
    @State var lastWidth: CGFloat = 0.0
    @State var progressWidth: CGFloat = 0.0
    var totalAmount: Double {
        sliderRange.upperBound - sliderRange.lowerBound
    }
    var start: Double {
        sliderRange.lowerBound
    }
    var end: Double {
        sliderRange.upperBound
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let thumbSize = height
            let barHeight = thumbSize / 4
            let slideWidth = width - thumbSize
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .foregroundColor(color.opacity(0.2))
                    .frame(height: barHeight)
                    .padding(.horizontal, thumbSize / 2)
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .foregroundColor(color.opacity(0.6))
                    .frame(width: progressWidth, height: barHeight)
                    .padding(.horizontal, thumbSize / 2)
                Circle()
                    .frame(width: thumbSize, height: thumbSize)
                    .foregroundColor(.thumb)
                    .overlay {
                        Circle()
                            .strokeBorder(lineWidth: 3)
                            .foregroundColor(color.opacity(0.6))
                    }
                    .offset(x: progressWidth)
                    .gesture(
                        DragGesture()
                            .onChanged { g in
                                progressWidth = calculateProgressWidth(gesture: g, slideWidth: slideWidth)
                                value = (progressWidth / slideWidth) * totalAmount + start
                            }
                            .onEnded { g in
                                progressWidth = calculateProgressWidth(gesture: g, slideWidth: slideWidth)
                                value = (progressWidth / slideWidth) * totalAmount + start
                                lastWidth = progressWidth
                            }
                    )
            }.onAppear {
                progressWidth = valueToProgressWidth(slideWidth: slideWidth)
                lastWidth = progressWidth
            }
        }
    }

    func calculateProgressWidth(gesture: DragGesture.Value, slideWidth: CGFloat) -> CGFloat {
        let translateX = gesture.translation.width
        let changingWidth = (lastWidth + translateX)
        return min(slideWidth, max(0, changingWidth))
    }

    func valueToProgressWidth(slideWidth: CGFloat) -> CGFloat {
        return slideWidth * value / totalAmount
    }
}

struct SliderView_Previews: PreviewProvider {
    @State static var value: Double = 1
    
    static var previews: some View {
        SliderView(value: $value)
            .frame(height: 20)
            .onChange(of: value) { newValue in
                print("---\(newValue)")
            }
    }
}
