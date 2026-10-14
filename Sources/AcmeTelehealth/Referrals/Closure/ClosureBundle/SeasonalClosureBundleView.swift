import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal closure bundle.
    final class SeasonalClosureBundleView {
        var code: String
        var label: String
        var rate: String
        var amount: String
        var budget: String
        var category: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, rate: String, amount: String, budget: String, category: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rate = rate
            self.amount = amount
            self.budget = budget
            self.category = category
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalClosureBundleView(_ item: SeasonalClosureBundle) -> SeasonalClosureBundleView {
        return SeasonalClosureBundleView(
            code: item.code,
            label: item.label,
            rate: String(format: "%.2f", item.rate),
            amount: String(format: "%.2f", item.amount),
            budget: String(format: "%.2f", item.budget),
            category: Kit.Text.truncate(item.category, limit: 40),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalClosureBundleViews(_ items: [SeasonalClosureBundle]) -> [SeasonalClosureBundleView] {
        var views: [SeasonalClosureBundleView] = []
        for item in items {
            views.append(toSeasonalClosureBundleView(item))
        }
        return views
    }

    static func sumSeasonalClosureBundleView(_ view: SeasonalClosureBundleView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRate + parsedAmount + parsedBudget
    }
}
