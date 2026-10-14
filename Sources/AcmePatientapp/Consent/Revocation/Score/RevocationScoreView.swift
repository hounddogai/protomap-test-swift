import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation score.
    final class RevocationScoreView {
        var codeText: String
        var label: String
        var visibleText: String
        var budgetText: String
        var expiresAt: String
        var updatedAtText: String
        var externalRef: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, visibleText: String, budgetText: String, expiresAt: String, updatedAtText: String, externalRef: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.visibleText = visibleText
            self.budgetText = budgetText
            self.expiresAt = expiresAt
            self.updatedAtText = updatedAtText
            self.externalRef = externalRef
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationScoreView(_ item: RevocationScore) -> RevocationScoreView {
        return RevocationScoreView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            visibleText: "\(item.visible)",
            budgetText: String(format: "%.2f", item.budget),
            expiresAt: String(item.expiresAt),
            updatedAtText: String(item.updatedAt),
            externalRef: item.externalRef,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationScoreViews(_ items: [RevocationScore]) -> [RevocationScoreView] {
        var views: [RevocationScoreView] = []
        for item in items {
            views.append(toRevocationScoreView(item))
        }
        return views
    }

    static func sumRevocationScoreView(_ view: RevocationScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedBudget + Double(parsedExpiresAt) + Double(parsedUpdatedAt)
    }
}
