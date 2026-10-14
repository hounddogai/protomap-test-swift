import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff checkpoint.
    final class HandoffCheckpointView {
        var code: String
        var title: String
        var graceDays: String
        var expiresAtText: String
        var diagnosisCodeText: String
        var patientRef: String
        var contactEmailText: String
        var externalRefText: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, expiresAtText: String, diagnosisCodeText: String, patientRef: String, contactEmailText: String, externalRefText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.expiresAtText = expiresAtText
            self.diagnosisCodeText = diagnosisCodeText
            self.patientRef = patientRef
            self.contactEmailText = contactEmailText
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffCheckpointView(_ item: HandoffCheckpoint) -> HandoffCheckpointView {
        return HandoffCheckpointView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            graceDays: String(item.graceDays),
            expiresAtText: String(item.expiresAt),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffCheckpointViews(_ items: [HandoffCheckpoint]) -> [HandoffCheckpointView] {
        var views: [HandoffCheckpointView] = []
        for item in items {
            views.append(toHandoffCheckpointView(item))
        }
        return views
    }

    static func sumHandoffCheckpointView(_ view: HandoffCheckpointView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt)
    }
}
