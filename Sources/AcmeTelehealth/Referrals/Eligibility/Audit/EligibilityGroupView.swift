import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility group.
    final class EligibilityGroupView {
        var code: String
        var titleText: String
        var summary: String
        var diagnosisCodeText: String
        var specialty: String
        var procedureCode: String
        var unit: String
        var attempts: String
        var graceDays: String
        var endsAtText: String
        var statusLabel: String

        init(code: String, titleText: String, summary: String, diagnosisCodeText: String, specialty: String, procedureCode: String, unit: String, attempts: String, graceDays: String, endsAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.summary = summary
            self.diagnosisCodeText = diagnosisCodeText
            self.specialty = specialty
            self.procedureCode = procedureCode
            self.unit = unit
            self.attempts = attempts
            self.graceDays = graceDays
            self.endsAtText = endsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityGroupView(_ item: EligibilityGroup) -> EligibilityGroupView {
        return EligibilityGroupView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            summary: item.summary,
            diagnosisCodeText: item.diagnosisCode,
            specialty: item.specialty,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            attempts: String(item.attempts),
            graceDays: String(item.graceDays),
            endsAtText: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityGroupViews(_ items: [EligibilityGroup]) -> [EligibilityGroupView] {
        var views: [EligibilityGroupView] = []
        for item in items {
            views.append(toEligibilityGroupView(item))
        }
        return views
    }

    static func sumEligibilityGroupView(_ view: EligibilityGroupView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedGraceDays) + Double(parsedEndsAt)
    }
}
