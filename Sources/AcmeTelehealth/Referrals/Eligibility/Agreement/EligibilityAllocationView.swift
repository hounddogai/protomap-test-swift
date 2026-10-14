import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility allocation.
    final class EligibilityAllocationView {
        var codeText: String
        var title: String
        var country: String
        var cost: String
        var margin: String
        var region: String
        var amountText: String
        var retries: String
        var statusLabel: String

        init(codeText: String, title: String, country: String, cost: String, margin: String, region: String, amountText: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.country = country
            self.cost = cost
            self.margin = margin
            self.region = region
            self.amountText = amountText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityAllocationView(_ item: EligibilityAllocation) -> EligibilityAllocationView {
        return EligibilityAllocationView(
            codeText: item.code,
            title: item.title,
            country: item.country,
            cost: String(format: "%.2f", item.cost),
            margin: String(format: "%.2f", item.margin),
            region: Kit.Text.truncate(item.region, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityAllocationViews(_ items: [EligibilityAllocation]) -> [EligibilityAllocationView] {
        var views: [EligibilityAllocationView] = []
        for item in items {
            views.append(toEligibilityAllocationView(item))
        }
        return views
    }

    static func sumEligibilityAllocationView(_ view: EligibilityAllocationView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedCost + parsedMargin + parsedAmount
    }
}
