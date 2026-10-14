import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score rule.
    final class RiskScoreRuleView {
        var code: String
        var labelText: String
        var visible: String
        var unitText: String
        var sequence: String
        var locale: String
        var encounterID: String
        var phone: String
        var attemptsText: String
        var weight: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, labelText: String, visible: String, unitText: String, sequence: String, locale: String, encounterID: String, phone: String, attemptsText: String, weight: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.visible = visible
            self.unitText = unitText
            self.sequence = sequence
            self.locale = locale
            self.encounterID = encounterID
            self.phone = phone
            self.attemptsText = attemptsText
            self.weight = weight
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreRuleView(_ item: RiskScoreRule) -> RiskScoreRuleView {
        return RiskScoreRuleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            visible: "\(item.visible)",
            unitText: item.unit,
            sequence: String(item.sequence),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            encounterID: item.encounterID,
            phone: item.phone,
            attemptsText: String(item.attempts),
            weight: String(format: "%.2f", item.weight),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreRuleViews(_ items: [RiskScoreRule]) -> [RiskScoreRuleView] {
        var views: [RiskScoreRuleView] = []
        for item in items {
            views.append(toRiskScoreRuleView(item))
        }
        return views
    }

    static func sumRiskScoreRuleView(_ view: RiskScoreRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedSequence) + Double(parsedAttempts) + parsedWeight
    }
}
