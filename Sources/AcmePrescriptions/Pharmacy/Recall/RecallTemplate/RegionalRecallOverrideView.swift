import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional recall override.
    final class RegionalRecallOverrideView {
        var code: String
        var label: String
        var ceiling: String
        var budget: String
        var currency: String
        var channel: String
        var bed: String
        var pinned: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, budget: String, currency: String, channel: String, bed: String, pinned: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.budget = budget
            self.currency = currency
            self.channel = channel
            self.bed = bed
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRecallOverrideView(_ item: RegionalRecallOverride) -> RegionalRecallOverrideView {
        return RegionalRecallOverrideView(
            code: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            budget: String(format: "%.2f", item.budget),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 64),
            bed: item.bed,
            pinned: "\(item.pinned)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRecallOverrideViews(_ items: [RegionalRecallOverride]) -> [RegionalRecallOverrideView] {
        var views: [RegionalRecallOverrideView] = []
        for item in items {
            views.append(toRegionalRecallOverrideView(item))
        }
        return views
    }

    static func sumRegionalRecallOverrideView(_ view: RegionalRecallOverrideView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedCeiling + parsedBudget
    }
}
