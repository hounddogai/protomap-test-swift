import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix audit.
    final class SkillMixAuditView {
        var codeText: String
        var title: String
        var reviewer: String
        var score: String
        var copay: String
        var approvedText: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, title: String, reviewer: String, score: String, copay: String, approvedText: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.reviewer = reviewer
            self.score = score
            self.copay = copay
            self.approvedText = approvedText
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixAuditView(_ item: SkillMixAudit) -> SkillMixAuditView {
        return SkillMixAuditView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 80),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            score: String(format: "%.2f", item.score),
            copay: String(format: "%.2f", item.copay),
            approvedText: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixAuditViews(_ items: [SkillMixAudit]) -> [SkillMixAuditView] {
        var views: [SkillMixAuditView] = []
        for item in items {
            views.append(toSkillMixAuditView(item))
        }
        return views
    }

    static func sumSkillMixAuditView(_ view: SkillMixAuditView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedScore + parsedCopay + Double(parsedExpiresAt)
    }
}
