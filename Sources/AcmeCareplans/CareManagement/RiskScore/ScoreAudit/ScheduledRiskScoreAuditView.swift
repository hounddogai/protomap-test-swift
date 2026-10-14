import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled risk score audit.
    final class ScheduledRiskScoreAuditView {
        var code: String
        var title: String
        var ownerIDText: String
        var dosageMg: String
        var patientRef: String
        var endsAt: String
        var sequenceText: String
        var attempts: String
        var payerText: String
        var statusLabel: String

        init(code: String, title: String, ownerIDText: String, dosageMg: String, patientRef: String, endsAt: String, sequenceText: String, attempts: String, payerText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerIDText = ownerIDText
            self.dosageMg = dosageMg
            self.patientRef = patientRef
            self.endsAt = endsAt
            self.sequenceText = sequenceText
            self.attempts = attempts
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRiskScoreAuditView(_ item: ScheduledRiskScoreAudit) -> ScheduledRiskScoreAuditView {
        return ScheduledRiskScoreAuditView(
            code: item.code,
            title: item.title,
            ownerIDText: item.ownerID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            patientRef: item.patientRef,
            endsAt: String(item.endsAt),
            sequenceText: String(item.sequence),
            attempts: String(item.attempts),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRiskScoreAuditViews(_ items: [ScheduledRiskScoreAudit]) -> [ScheduledRiskScoreAuditView] {
        var views: [ScheduledRiskScoreAuditView] = []
        for item in items {
            views.append(toScheduledRiskScoreAuditView(item))
        }
        return views
    }

    static func sumScheduledRiskScoreAuditView(_ view: ScheduledRiskScoreAuditView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedDosageMg + Double(parsedEndsAt) + Double(parsedSequence)
    }
}
