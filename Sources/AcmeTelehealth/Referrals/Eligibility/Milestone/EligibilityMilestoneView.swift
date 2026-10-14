import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility milestone.
    final class EligibilityMilestoneView {
        var codeText: String
        var nameText: String
        var archived: String
        var diagnosisCode: String
        var acuity: String
        var maximum: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, nameText: String, archived: String, diagnosisCode: String, acuity: String, maximum: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.archived = archived
            self.diagnosisCode = diagnosisCode
            self.acuity = acuity
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityMilestoneView(_ item: EligibilityMilestone) -> EligibilityMilestoneView {
        return EligibilityMilestoneView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            archived: "\(item.archived)",
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            acuity: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityMilestoneViews(_ items: [EligibilityMilestone]) -> [EligibilityMilestoneView] {
        var views: [EligibilityMilestoneView] = []
        for item in items {
            views.append(toEligibilityMilestoneView(item))
        }
        return views
    }

    static func sumEligibilityMilestoneView(_ view: EligibilityMilestoneView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedAcuity) + parsedMaximum + Double(parsedDurationMinutes)
    }
}
