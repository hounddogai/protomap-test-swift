import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default result audit.
    final class DefaultResultAuditView {
        var codeText: String
        var title: String
        var approved: String
        var startsAt: String
        var copayText: String
        var pinnedText: String
        var timezone: String
        var expiresAt: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, title: String, approved: String, startsAt: String, copayText: String, pinnedText: String, timezone: String, expiresAt: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.approved = approved
            self.startsAt = startsAt
            self.copayText = copayText
            self.pinnedText = pinnedText
            self.timezone = timezone
            self.expiresAt = expiresAt
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultResultAuditView(_ item: DefaultResultAudit) -> DefaultResultAuditView {
        return DefaultResultAuditView(
            codeText: item.code,
            title: item.title,
            approved: "\(item.approved)",
            startsAt: String(item.startsAt),
            copayText: String(format: "%.2f", item.copay),
            pinnedText: "\(item.pinned)",
            timezone: item.timezone,
            expiresAt: String(item.expiresAt),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultResultAuditViews(_ items: [DefaultResultAudit]) -> [DefaultResultAuditView] {
        var views: [DefaultResultAuditView] = []
        for item in items {
            views.append(toDefaultResultAuditView(item))
        }
        return views
    }

    static func sumDefaultResultAuditView(_ view: DefaultResultAuditView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedStartsAt) + parsedCopay + Double(parsedExpiresAt)
    }
}
