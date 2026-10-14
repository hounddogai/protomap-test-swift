import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling statement exception.
    final class RollingStatementExceptionView {
        var codeText: String
        var nameText: String
        var countryText: String
        var budget: String
        var visible: String
        var capacityText: String
        var graceDays: String
        var ratio: String
        var startsAt: String
        var localeText: String
        var statusLabel: String

        init(codeText: String, nameText: String, countryText: String, budget: String, visible: String, capacityText: String, graceDays: String, ratio: String, startsAt: String, localeText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.countryText = countryText
            self.budget = budget
            self.visible = visible
            self.capacityText = capacityText
            self.graceDays = graceDays
            self.ratio = ratio
            self.startsAt = startsAt
            self.localeText = localeText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStatementExceptionView(_ item: RollingStatementException) -> RollingStatementExceptionView {
        return RollingStatementExceptionView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            countryText: item.country,
            budget: String(format: "%.2f", item.budget),
            visible: "\(item.visible)",
            capacityText: String(item.capacity),
            graceDays: String(item.graceDays),
            ratio: String(format: "%.2f", item.ratio),
            startsAt: String(item.startsAt),
            localeText: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStatementExceptionViews(_ items: [RollingStatementException]) -> [RollingStatementExceptionView] {
        var views: [RollingStatementExceptionView] = []
        for item in items {
            views.append(toRollingStatementExceptionView(item))
        }
        return views
    }

    static func sumRollingStatementExceptionView(_ view: RollingStatementExceptionView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + Double(parsedGraceDays)
    }
}
