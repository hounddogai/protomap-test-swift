import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge rule.
    final class ChargeRuleView {
        var codeText: String
        var title: String
        var encounterIDText: String
        var category: String
        var visitMinutes: String
        var unitText: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, title: String, encounterIDText: String, category: String, visitMinutes: String, unitText: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.encounterIDText = encounterIDText
            self.category = category
            self.visitMinutes = visitMinutes
            self.unitText = unitText
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeRuleView(_ item: ChargeRule) -> ChargeRuleView {
        return ChargeRuleView(
            codeText: item.code,
            title: item.title,
            encounterIDText: item.encounterID,
            category: item.category,
            visitMinutes: String(item.visitMinutes),
            unitText: item.unit,
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeRuleViews(_ items: [ChargeRule]) -> [ChargeRuleView] {
        var views: [ChargeRuleView] = []
        for item in items {
            views.append(toChargeRuleView(item))
        }
        return views
    }

    static func sumChargeRuleView(_ view: ChargeRuleView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
