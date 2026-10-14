import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff audit.
    final class HandoffAuditView {
        var codeText: String
        var labelText: String
        var sequence: String
        var channelText: String
        var ceiling: String
        var approved: String
        var bed: String
        var statusLabel: String

        init(codeText: String, labelText: String, sequence: String, channelText: String, ceiling: String, approved: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.sequence = sequence
            self.channelText = channelText
            self.ceiling = ceiling
            self.approved = approved
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffAuditView(_ item: HandoffAudit) -> HandoffAuditView {
        return HandoffAuditView(
            codeText: item.code,
            labelText: item.label,
            sequence: String(item.sequence),
            channelText: Kit.Text.truncate(item.channel, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            approved: "\(item.approved)",
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffAuditViews(_ items: [HandoffAudit]) -> [HandoffAuditView] {
        var views: [HandoffAuditView] = []
        for item in items {
            views.append(toHandoffAuditView(item))
        }
        return views
    }

    static func sumHandoffAuditView(_ view: HandoffAuditView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedSequence) + parsedCeiling
    }
}
