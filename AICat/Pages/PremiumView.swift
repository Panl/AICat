//
//  PremiumView.swift
//  AICat
//
//  Created by Lei Pan on 2023/4/13.
//

import SwiftUI
import ApphudSDK
import Perception

@Perceptible
class PremiumPageViewModel {
    var product: ApphudProduct?
    var isPurchasing: Bool = false
    var toast: Toast?

    var price: String {
        product?.skProduct?.locatedPrice ?? "_._"
    }

    var isPremium: Bool {
        UserDefaults.openApiKey != nil || UserDefaults.hasPremiumAccess
    }

    func fetchMonthlyProduct() {
        Task {
            let payWall = await Apphud.placements().first?.paywall
            product = payWall?.products.first(where: { $0.productId == monthlyPremiumId })
        }
    }

    func subscribeNow() {
        guard !isPurchasing, !isPremium, let product else { return }
        if Apphud.isSandbox() {
            toast = Toast(type: .info, message: "😿 Please use the App Store build")
            return
        }
        isPurchasing = true
        Task {
            let result = await Apphud.purchase(product)
            UserDefaults.hasPremiumAccess = await Apphud.hasPremiumAccess()
            if result.success {
                toast = Toast(type: .success, message: "You get AICat Premium Now!", duration: 2)
            }
            if let error = result.error as? NSError {
                toast = Toast(type: .error, message: "Purchase failed, \(error.localizedDescription))", duration: 4)
            } else if result.error != nil {
                toast = Toast(type: .error, message: "Purchase failed!", duration: 2)
            }
            isPurchasing = false
        }
    }

    func restorePurchases() {
        guard !isPurchasing, product != nil else { return }
        isPurchasing = true
        Task {
            let _ = await Apphud.restorePurchases()
            UserDefaults.hasPremiumAccess = await Apphud.hasPremiumAccess()
            isPurchasing = false
            if isPremium {
                toast = Toast(type: .success, message: "You get AICat Premium Now!", duration: 2)
            } else {
                toast = Toast(type: .error, message: "You are not premium user!", duration: 2)
            }
        }
    }
}

struct PremiumPage: View {

    @State var viewModel = PremiumPageViewModel()
    let onClose: () -> Void

    var body: some View {
        WithPerceptionTracking {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(16)
                    }
                    .tint(.primaryColor)
                    .buttonStyle(.borderless)
                }
                Spacer()
                Text("AICat Premium")
                    .font(.manrope(size: 36, weight: .bold))
                    .fontWeight(.bold)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    FeatureView(title: "Answers from GPT Model", description: "Get accurate and relevant answers directly from the GPT Model.")
                    FeatureView(title: "Higher token limit for dialogues", description: "Engage in dialogues with a higer token limit")
                    FeatureView(title: "Unlimited custom prompts", description: "Enjoy different conversations without any restrictions")
                    FeatureView(title: "iCloud Sync", description: "Sync all conversations and messages across different devices.")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                Spacer()
                Button(action: {
                    viewModel.restorePurchases()
                }) {
                    Text("Restore Purchases")
                        .underline()
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                Button(action: {
                    viewModel.subscribeNow()
                }) {
                    ZStack {
                        Text(viewModel.isPremium ? "Already Premium" : String(format: NSLocalizedString("Subscribe for %@/month", comment: ""), viewModel.price))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .opacity((viewModel.isPurchasing) ? 0 : 1)
                            .background(Color.blue)
                            .cornerRadius(8)
                        if viewModel.isPurchasing {
                            LoadingIndocator(themeColor: .white)
                                .frame(width: 20, height: 20)
                                .environment(\.colorScheme, .dark)
                        }
                    }

                }
                .buttonStyle(.borderless)
                Text("Auto renewal monthly, cancel at anytime")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.manrope(size: 12, weight: .regular))
                    .padding(.bottom, 10)

                HStack {
                    Link(destination: URL(string: "https://epochpro.app/aicat_privacy")!) {
                        Text("Privacy Policy")
                            .underline()
                            .foregroundColor(.blue)
                    }

                    Text("|")
                        .padding(.horizontal, 4)

                    Link(destination: URL(string: "https://epochpro.app/aicat_terms_of_use")!) {
                        Text("Terms of Use")
                            .underline()
                            .foregroundColor(.blue)
                    }
                }
                .font(.footnote)
                .padding(.bottom, 20)
                Spacer()
            }
            .font(.manrope(size: 16, weight: .medium))
            .onAppear {
                viewModel.fetchMonthlyProduct()
            }
            .background(Color.background.ignoresSafeArea())
            .toast($viewModel.toast)
        }
    }
}

struct FeatureView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "crown.fill")

                Text(LocalizedStringKey(title))
                    .font(.manrope(size: 16, weight: .bold))
            }

            Text(LocalizedStringKey(description))
                .font(.manrope(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.leading, 32)
        }
    }
}

struct PremiumPage_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPage(onClose: {})
            .background(.background)
            .environment(\.colorScheme, .dark)
    }
}

