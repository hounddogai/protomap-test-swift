import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal audit.
    final class GoalAuditView {
        var codeText: String
        var label: String
        var expiresAtText: String
        var rate: String
        var sequence: String
        var dosageMg: String
        var diagnosisCodeText: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAtText: String, rate: String, sequence: String, dosageMg: String, diagnosisCodeText: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAtText = expiresAtText
            self.rate = rate
            self.sequence = sequence
            self.dosageMg = dosageMg
            self.diagnosisCodeText = diagnosisCodeText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalAuditView(_ item: GoalAudit) -> GoalAuditView {
        return GoalAuditView(
            codeText: item.code,
            label: item.label,
            expiresAtText: String(item.expiresAt),
            rate: String(format: "%.2f", item.rate),
            sequence: String(item.sequence),
            dosageMg: String(format: "%.2f", item.dosageMg),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalAuditViews(_ items: [GoalAudit]) -> [GoalAuditView] {
        var views: [GoalAuditView] = []
        for item in items {
            views.append(toGoalAuditView(item))
        }
        return views
    }

    static func sumGoalAuditView(_ view: GoalAuditView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedExpiresAt) + parsedRate + Double(parsedSequence)
    }
}
