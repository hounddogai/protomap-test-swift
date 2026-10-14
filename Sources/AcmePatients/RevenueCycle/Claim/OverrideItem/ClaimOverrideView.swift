import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim override.
    final class ClaimOverrideView {
        var codeText: String
        var label: String
        var weight: String
        var visitMinutes: String
        var endsAt: String
        var summary: String
        var expiresAtText: String
        var reviewer: String
        var currency: String
        var statusLabel: String

        init(codeText: String, label: String, weight: String, visitMinutes: String, endsAt: String, summary: String, expiresAtText: String, reviewer: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.endsAt = endsAt
            self.summary = summary
            self.expiresAtText = expiresAtText
            self.reviewer = reviewer
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toClaimOverrideView(_ item: ClaimOverride) -> ClaimOverrideView {
        return ClaimOverrideView(
            codeText: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            visitMinutes: String(item.visitMinutes),
            endsAt: String(item.endsAt),
            summary: item.summary,
            expiresAtText: String(item.expiresAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimOverrideViews(_ items: [ClaimOverride]) -> [ClaimOverrideView] {
        var views: [ClaimOverrideView] = []
        for item in items {
            views.append(toClaimOverrideView(item))
        }
        return views
    }

    static func sumClaimOverrideView(_ view: ClaimOverrideView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedWeight + Double(parsedVisitMinutes) + Double(parsedEndsAt)
    }
}
