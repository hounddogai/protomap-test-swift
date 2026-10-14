import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure budget.
    final class DisclosureBudgetView {
        var code: String
        var titleText: String
        var country: String
        var active: String
        var acuity: String
        var description: String
        var patientRef: String
        var diagnosisCode: String
        var scoreText: String
        var attempts: String
        var statusLabel: String

        init(code: String, titleText: String, country: String, active: String, acuity: String, description: String, patientRef: String, diagnosisCode: String, scoreText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.country = country
            self.active = active
            self.acuity = acuity
            self.description = description
            self.patientRef = patientRef
            self.diagnosisCode = diagnosisCode
            self.scoreText = scoreText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureBudgetView(_ item: DisclosureBudget) -> DisclosureBudgetView {
        return DisclosureBudgetView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            country: item.country,
            active: "\(item.active)",
            acuity: String(item.acuity),
            description: Kit.Text.truncate(item.description, limit: 120),
            patientRef: item.patientRef,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureBudgetViews(_ items: [DisclosureBudget]) -> [DisclosureBudgetView] {
        var views: [DisclosureBudgetView] = []
        for item in items {
            views.append(toDisclosureBudgetView(item))
        }
        return views
    }

    static func sumDisclosureBudgetView(_ view: DisclosureBudgetView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAcuity) + parsedScore + Double(parsedAttempts)
    }
}
