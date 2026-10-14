import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal isolation rule.
    final class SeasonalIsolationRuleView {
        var code: String
        var labelText: String
        var allergyText: String
        var diagnosisCode: String
        var copay: String
        var statusLabel: String

        init(code: String, labelText: String, allergyText: String, diagnosisCode: String, copay: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.allergyText = allergyText
            self.diagnosisCode = diagnosisCode
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalIsolationRuleView(_ item: SeasonalIsolationRule) -> SeasonalIsolationRuleView {
        return SeasonalIsolationRuleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            allergyText: item.allergy,
            diagnosisCode: item.diagnosisCode,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalIsolationRuleViews(_ items: [SeasonalIsolationRule]) -> [SeasonalIsolationRuleView] {
        var views: [SeasonalIsolationRuleView] = []
        for item in items {
            views.append(toSeasonalIsolationRuleView(item))
        }
        return views
    }

    static func sumSeasonalIsolationRuleView(_ view: SeasonalIsolationRuleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
