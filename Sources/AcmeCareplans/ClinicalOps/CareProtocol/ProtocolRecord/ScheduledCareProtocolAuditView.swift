import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled care protocol audit.
    final class ScheduledCareProtocolAuditView {
        var code: String
        var label: String
        var score: String
        var archived: String
        var clinicianID: String
        var channel: String
        var payer: String
        var notesText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, label: String, score: String, archived: String, clinicianID: String, channel: String, payer: String, notesText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.archived = archived
            self.clinicianID = clinicianID
            self.channel = channel
            self.payer = payer
            self.notesText = notesText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolAuditView(_ item: ScheduledCareProtocolAudit) -> ScheduledCareProtocolAuditView {
        return ScheduledCareProtocolAuditView(
            code: item.code,
            label: item.label,
            score: String(format: "%.2f", item.score),
            archived: "\(item.archived)",
            clinicianID: item.clinicianID,
            channel: item.channel,
            payer: Kit.Text.truncate(item.payer, limit: 80),
            notesText: item.notes,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolAuditViews(_ items: [ScheduledCareProtocolAudit]) -> [ScheduledCareProtocolAuditView] {
        var views: [ScheduledCareProtocolAuditView] = []
        for item in items {
            views.append(toScheduledCareProtocolAuditView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolAuditView(_ view: ScheduledCareProtocolAuditView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
