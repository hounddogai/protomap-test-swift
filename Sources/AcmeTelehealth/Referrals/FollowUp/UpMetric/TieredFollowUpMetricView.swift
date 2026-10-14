import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered follow up metric.
    final class TieredFollowUpMetricView {
        var code: String
        var label: String
        var durationMinutesText: String
        var cost: String
        var unit: String
        var approved: String
        var budget: String
        var ceilingText: String
        var sequence: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, durationMinutesText: String, cost: String, unit: String, approved: String, budget: String, ceilingText: String, sequence: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.durationMinutesText = durationMinutesText
            self.cost = cost
            self.unit = unit
            self.approved = approved
            self.budget = budget
            self.ceilingText = ceilingText
            self.sequence = sequence
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredFollowUpMetricView(_ item: TieredFollowUpMetric) -> TieredFollowUpMetricView {
        return TieredFollowUpMetricView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            cost: String(format: "%.2f", item.cost),
            unit: item.unit,
            approved: "\(item.approved)",
            budget: String(format: "%.2f", item.budget),
            ceilingText: String(format: "%.2f", item.ceiling),
            sequence: String(item.sequence),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredFollowUpMetricViews(_ items: [TieredFollowUpMetric]) -> [TieredFollowUpMetricView] {
        var views: [TieredFollowUpMetricView] = []
        for item in items {
            views.append(toTieredFollowUpMetricView(item))
        }
        return views
    }

    static func sumTieredFollowUpMetricView(_ view: TieredFollowUpMetricView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedDurationMinutes) + parsedCost + parsedBudget
    }
}
