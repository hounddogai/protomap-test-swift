import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global specimen rule.
    final class GlobalSpecimenRuleView {
        var code: String
        var title: String
        var allergy: String
        var contactEmailText: String
        var acuityText: String
        var windowDays: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, title: String, allergy: String, contactEmailText: String, acuityText: String, windowDays: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.contactEmailText = contactEmailText
            self.acuityText = acuityText
            self.windowDays = windowDays
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSpecimenRuleView(_ item: GlobalSpecimenRule) -> GlobalSpecimenRuleView {
        return GlobalSpecimenRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            allergy: item.allergy,
            contactEmailText: item.contactEmail,
            acuityText: String(item.acuity),
            windowDays: String(item.windowDays),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSpecimenRuleViews(_ items: [GlobalSpecimenRule]) -> [GlobalSpecimenRuleView] {
        var views: [GlobalSpecimenRuleView] = []
        for item in items {
            views.append(toGlobalSpecimenRuleView(item))
        }
        return views
    }

    static func sumGlobalSpecimenRuleView(_ view: GlobalSpecimenRuleView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAcuity) + Double(parsedWindowDays) + Double(parsedAttempts)
    }
}
