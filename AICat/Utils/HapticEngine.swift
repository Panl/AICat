//
//  HapticEngine.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/17.
//

import UIKit

public enum HapticEngine {

  private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)

  private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

  private static let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

  private static let selectionGenerator = UISelectionFeedbackGenerator()

  private static var notificationGenerator = UINotificationFeedbackGenerator()

  public enum ImpactFeedbackGeneratorStyle {
    case light, medium, heavy
  }

  public enum NotificationFeedbackGeneratorType {
    case success, warning, error
  }

  public enum FeedbackGeneratorType {
    case impact(type: ImpactFeedbackGeneratorStyle)
    case selection
    case notification(type: NotificationFeedbackGeneratorType)
  }

  private static func getGenerator(of type: FeedbackGeneratorType) -> UIFeedbackGenerator {
    switch type {
    case .impact(type: .light):
      return lightImpactGenerator
    case .impact(type: .medium):
      return mediumImpactGenerator
    case .impact(type: .heavy):
      return heavyImpactGenerator
    case .selection:
      return selectionGenerator
    case .notification:
      return notificationGenerator
    }
  }

  public static func prepare(type: FeedbackGeneratorType) {
    let generator = getGenerator(of: type)
    generator.prepare()
  }

  public static func trigger(type: FeedbackGeneratorType = .impact(type: .light)) {
    let generator = getGenerator(of: type)
    switch type {
    case .impact:
      (generator as? UIImpactFeedbackGenerator)?.impactOccurred()
    case .selection:
      (generator as? UISelectionFeedbackGenerator)?.selectionChanged()
    case .notification(type: .success):
      (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.success)
    case .notification(type: .warning):
      (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.warning)
    case .notification(type: .error):
      (generator as? UINotificationFeedbackGenerator)?.notificationOccurred(.error)
    }
  }
}
