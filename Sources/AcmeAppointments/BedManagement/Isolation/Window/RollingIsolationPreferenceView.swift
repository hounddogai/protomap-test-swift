import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling isolation preference.
    final class RollingIsolationPreferenceView {
        var code: String
        var nameText: String
        var cost: String
        var ceiling: String
        var localeText: String
        var limit: String
        var priority: String
        var graceDays: String
        var payerText: String
        var attemptsText: String
        var budget: String
        var statusLabel: String

        init(code: String, nameText: String, cost: String, ceiling: String, localeText: String, limit: String, priority: String, graceDays: String, payerText: String, attemptsText: String, budget: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.cost = cost
            self.ceiling = ceiling
            self.localeText = localeText
            self.limit = limit
            self.priority = priority
            self.graceDays = graceDays
            self.payerText = payerText
            self.attemptsText = attemptsText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toRollingIsolationPreferenceView(_ item: RollingIsolationPreference) -> RollingIsolationPreferenceView {
        return RollingIsolationPreferenceView(
            code: item.code,
            nameText: item.name,
            cost: String(format: "%.2f", item.cost),
            ceiling: String(format: "%.2f", item.ceiling),
            localeText: item.locale,
            limit: String(item.limit),
            priority: String(item.priority),
            graceDays: String(item.graceDays),
            payerText: item.payer,
            attemptsText: String(item.attempts),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingIsolationPreferenceViews(_ items: [RollingIsolationPreference]) -> [RollingIsolationPreferenceView] {
        var views: [RollingIsolationPreferenceView] = []
        for item in items {
            views.append(toRollingIsolationPreferenceView(item))
        }
        return views
    }

    static func sumRollingIsolationPreferenceView(_ view: RollingIsolationPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCost + parsedCeiling + Double(parsedLimit)
    }
}
