import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient statement rule.
    final class LenientStatementRuleView {
        var code: String
        var label: String
        var revision: String
        var patientRefText: String
        var visibleText: String
        var contactEmail: String
        var expiresAtText: String
        var endsAt: String
        var externalRef: String
        var priority: String
        var scoreText: String
        var statusLabel: String

        init(code: String, label: String, revision: String, patientRefText: String, visibleText: String, contactEmail: String, expiresAtText: String, endsAt: String, externalRef: String, priority: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.patientRefText = patientRefText
            self.visibleText = visibleText
            self.contactEmail = contactEmail
            self.expiresAtText = expiresAtText
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.priority = priority
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientStatementRuleView(_ item: LenientStatementRule) -> LenientStatementRuleView {
        return LenientStatementRuleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            revision: String(item.revision),
            patientRefText: item.patientRef,
            visibleText: "\(item.visible)",
            contactEmail: item.contactEmail,
            expiresAtText: String(item.expiresAt),
            endsAt: String(item.endsAt),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            priority: String(item.priority),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientStatementRuleViews(_ items: [LenientStatementRule]) -> [LenientStatementRuleView] {
        var views: [LenientStatementRuleView] = []
        for item in items {
            views.append(toLenientStatementRuleView(item))
        }
        return views
    }

    static func sumLenientStatementRuleView(_ view: LenientStatementRuleView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRevision) + Double(parsedExpiresAt) + Double(parsedEndsAt)
    }
}
