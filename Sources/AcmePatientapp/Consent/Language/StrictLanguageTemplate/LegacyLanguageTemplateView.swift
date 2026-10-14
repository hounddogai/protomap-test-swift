import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy language template.
    final class LegacyLanguageTemplateView {
        var code: String
        var title: String
        var refillsText: String
        var ownerID: String
        var locale: String
        var patientRefText: String
        var sourceText: String
        var ceiling: String
        var description: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, refillsText: String, ownerID: String, locale: String, patientRefText: String, sourceText: String, ceiling: String, description: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refillsText = refillsText
            self.ownerID = ownerID
            self.locale = locale
            self.patientRefText = patientRefText
            self.sourceText = sourceText
            self.ceiling = ceiling
            self.description = description
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyLanguageTemplateView(_ item: LegacyLanguageTemplate) -> LegacyLanguageTemplateView {
        return LegacyLanguageTemplateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            refillsText: String(item.refills),
            ownerID: item.ownerID,
            locale: item.locale,
            patientRefText: item.patientRef,
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            description: Kit.Text.truncate(item.description, limit: 64),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyLanguageTemplateViews(_ items: [LegacyLanguageTemplate]) -> [LegacyLanguageTemplateView] {
        var views: [LegacyLanguageTemplateView] = []
        for item in items {
            views.append(toLegacyLanguageTemplateView(item))
        }
        return views
    }

    static func sumLegacyLanguageTemplateView(_ view: LegacyLanguageTemplateView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRefills) + parsedCeiling
    }
}
