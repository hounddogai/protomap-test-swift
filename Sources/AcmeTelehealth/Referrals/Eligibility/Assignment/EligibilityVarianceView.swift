import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility variance.
    final class EligibilityVarianceView {
        var code: String
        var label: String
        var durationMinutes: String
        var quantity: String
        var discount: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, durationMinutes: String, quantity: String, discount: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.discount = discount
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityVarianceView(_ item: EligibilityVariance) -> EligibilityVarianceView {
        return EligibilityVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            durationMinutes: String(item.durationMinutes),
            quantity: String(item.quantity),
            discount: String(format: "%.2f", item.discount),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityVarianceViews(_ items: [EligibilityVariance]) -> [EligibilityVarianceView] {
        var views: [EligibilityVarianceView] = []
        for item in items {
            views.append(toEligibilityVarianceView(item))
        }
        return views
    }

    static func sumEligibilityVarianceView(_ view: EligibilityVarianceView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedQuantity) + parsedDiscount
    }
}
