import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback care protocol audit.
    final class FallbackCareProtocolAuditView {
        var codeText: String
        var title: String
        var endsAt: String
        var archived: String
        var nameText: String
        var approved: String
        var timezone: String
        var sequence: String
        var externalRef: String
        var statusLabel: String

        init(codeText: String, title: String, endsAt: String, archived: String, nameText: String, approved: String, timezone: String, sequence: String, externalRef: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.endsAt = endsAt
            self.archived = archived
            self.nameText = nameText
            self.approved = approved
            self.timezone = timezone
            self.sequence = sequence
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCareProtocolAuditView(_ item: FallbackCareProtocolAudit) -> FallbackCareProtocolAuditView {
        return FallbackCareProtocolAuditView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            endsAt: String(item.endsAt),
            archived: "\(item.archived)",
            nameText: item.name,
            approved: "\(item.approved)",
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            sequence: String(item.sequence),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCareProtocolAuditViews(_ items: [FallbackCareProtocolAudit]) -> [FallbackCareProtocolAuditView] {
        var views: [FallbackCareProtocolAuditView] = []
        for item in items {
            views.append(toFallbackCareProtocolAuditView(item))
        }
        return views
    }

    static func sumFallbackCareProtocolAuditView(_ view: FallbackCareProtocolAuditView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedSequence)
    }
}
