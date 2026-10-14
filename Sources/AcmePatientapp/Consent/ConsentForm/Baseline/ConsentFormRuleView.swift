import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form rule.
    final class ConsentFormRuleView {
        var codeText: String
        var name: String
        var clinicianIDText: String
        var visible: String
        var locale: String
        var score: String
        var statusLabel: String

        init(codeText: String, name: String, clinicianIDText: String, visible: String, locale: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.clinicianIDText = clinicianIDText
            self.visible = visible
            self.locale = locale
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormRuleView(_ item: ConsentFormRule) -> ConsentFormRuleView {
        return ConsentFormRuleView(
            codeText: item.code,
            name: item.name,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 120),
            visible: "\(item.visible)",
            locale: Kit.Text.truncate(item.locale, limit: 64),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormRuleViews(_ items: [ConsentFormRule]) -> [ConsentFormRuleView] {
        var views: [ConsentFormRuleView] = []
        for item in items {
            views.append(toConsentFormRuleView(item))
        }
        return views
    }

    static func sumConsentFormRuleView(_ view: ConsentFormRuleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
