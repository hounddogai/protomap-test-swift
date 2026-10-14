import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a fallback authorization claim.
    final class FallbackAuthorizationClaimView {
        var code: String
        var titleText: String
        var discount: String
        var bedText: String
        var amount: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, titleText: String, discount: String, bedText: String, amount: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.discount = discount
            self.bedText = bedText
            self.amount = amount
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAuthorizationClaimView(_ item: FallbackAuthorizationClaim) -> FallbackAuthorizationClaimView {
        return FallbackAuthorizationClaimView(
            code: item.code,
            titleText: item.title,
            discount: String(format: "%.2f", item.discount),
            bedText: item.bed,
            amount: String(format: "%.2f", item.amount),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAuthorizationClaimViews(_ items: [FallbackAuthorizationClaim]) -> [FallbackAuthorizationClaimView] {
        var views: [FallbackAuthorizationClaimView] = []
        for item in items {
            views.append(toFallbackAuthorizationClaimView(item))
        }
        return views
    }

    static func sumFallbackAuthorizationClaimView(_ view: FallbackAuthorizationClaimView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedDiscount + parsedAmount + parsedFloorValue
    }
}
