import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional eligibility estimate.
    final class RegionalEligibilityEstimateView {
        var codeText: String
        var titleText: String
        var checksum: String
        var visible: String
        var timezone: String
        var updatedAtText: String
        var ceiling: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, titleText: String, checksum: String, visible: String, timezone: String, updatedAtText: String, ceiling: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.checksum = checksum
            self.visible = visible
            self.timezone = timezone
            self.updatedAtText = updatedAtText
            self.ceiling = ceiling
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalEligibilityEstimateView(_ item: RegionalEligibilityEstimate) -> RegionalEligibilityEstimateView {
        return RegionalEligibilityEstimateView(
            codeText: item.code,
            titleText: item.title,
            checksum: item.checksum,
            visible: "\(item.visible)",
            timezone: item.timezone,
            updatedAtText: String(item.updatedAt),
            ceiling: String(format: "%.2f", item.ceiling),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalEligibilityEstimateViews(_ items: [RegionalEligibilityEstimate]) -> [RegionalEligibilityEstimateView] {
        var views: [RegionalEligibilityEstimateView] = []
        for item in items {
            views.append(toRegionalEligibilityEstimateView(item))
        }
        return views
    }

    static func sumRegionalEligibilityEstimateView(_ view: RegionalEligibilityEstimateView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCeiling + parsedAmount
    }
}
