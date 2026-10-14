import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled census budget.
    final class ScheduledCensusBudgetView {
        var code: String
        var name: String
        var active: String
        var locale: String
        var maximum: String
        var allergyText: String
        var visible: String
        var country: String
        var statusLabel: String

        init(code: String, name: String, active: String, locale: String, maximum: String, allergyText: String, visible: String, country: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.locale = locale
            self.maximum = maximum
            self.allergyText = allergyText
            self.visible = visible
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCensusBudgetView(_ item: ScheduledCensusBudget) -> ScheduledCensusBudgetView {
        return ScheduledCensusBudgetView(
            code: item.code,
            name: item.name,
            active: "\(item.active)",
            locale: Kit.Text.truncate(item.locale, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            visible: "\(item.visible)",
            country: Kit.Text.truncate(item.country, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCensusBudgetViews(_ items: [ScheduledCensusBudget]) -> [ScheduledCensusBudgetView] {
        var views: [ScheduledCensusBudgetView] = []
        for item in items {
            views.append(toScheduledCensusBudgetView(item))
        }
        return views
    }

    static func sumScheduledCensusBudgetView(_ view: ScheduledCensusBudgetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
