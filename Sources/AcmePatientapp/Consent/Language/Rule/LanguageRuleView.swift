import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language rule.
    final class LanguageRuleView {
        var code: String
        var title: String
        var refills: String
        var ceiling: String
        var durationMinutes: String
        var costText: String
        var reviewer: String
        var contactEmailText: String
        var ward: String
        var statusLabel: String

        init(code: String, title: String, refills: String, ceiling: String, durationMinutes: String, costText: String, reviewer: String, contactEmailText: String, ward: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refills = refills
            self.ceiling = ceiling
            self.durationMinutes = durationMinutes
            self.costText = costText
            self.reviewer = reviewer
            self.contactEmailText = contactEmailText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageRuleView(_ item: LanguageRule) -> LanguageRuleView {
        return LanguageRuleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            refills: String(item.refills),
            ceiling: String(format: "%.2f", item.ceiling),
            durationMinutes: String(item.durationMinutes),
            costText: String(format: "%.2f", item.cost),
            reviewer: item.reviewer,
            contactEmailText: item.contactEmail,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageRuleViews(_ items: [LanguageRule]) -> [LanguageRuleView] {
        var views: [LanguageRuleView] = []
        for item in items {
            views.append(toLanguageRuleView(item))
        }
        return views
    }

    static func sumLanguageRuleView(_ view: LanguageRuleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedRefills) + parsedCeiling + Double(parsedDurationMinutes)
    }
}
