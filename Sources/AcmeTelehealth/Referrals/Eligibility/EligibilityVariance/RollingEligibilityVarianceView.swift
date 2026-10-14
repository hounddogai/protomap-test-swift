import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling eligibility variance.
    final class RollingEligibilityVarianceView {
        var code: String
        var titleText: String
        var endsAt: String
        var ratio: String
        var quantity: String
        var weightText: String
        var statusLabel: String

        init(code: String, titleText: String, endsAt: String, ratio: String, quantity: String, weightText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAt = endsAt
            self.ratio = ratio
            self.quantity = quantity
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingEligibilityVarianceView(_ item: RollingEligibilityVariance) -> RollingEligibilityVarianceView {
        return RollingEligibilityVarianceView(
            code: item.code,
            titleText: item.title,
            endsAt: String(item.endsAt),
            ratio: String(format: "%.2f", item.ratio),
            quantity: String(item.quantity),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingEligibilityVarianceViews(_ items: [RollingEligibilityVariance]) -> [RollingEligibilityVarianceView] {
        var views: [RollingEligibilityVarianceView] = []
        for item in items {
            views.append(toRollingEligibilityVarianceView(item))
        }
        return views
    }

    static func sumRollingEligibilityVarianceView(_ view: RollingEligibilityVarianceView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedEndsAt) + parsedRatio + Double(parsedQuantity)
    }
}
