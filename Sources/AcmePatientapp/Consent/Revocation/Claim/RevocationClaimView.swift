import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation claim.
    final class RevocationClaimView {
        var code: String
        var title: String
        var revision: String
        var timezone: String
        var acuity: String
        var graceDays: String
        var createdAt: String
        var reviewerText: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, revision: String, timezone: String, acuity: String, graceDays: String, createdAt: String, reviewerText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.timezone = timezone
            self.acuity = acuity
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.reviewerText = reviewerText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationClaimView(_ item: RevocationClaim) -> RevocationClaimView {
        return RevocationClaimView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            revision: String(item.revision),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            acuity: String(item.acuity),
            graceDays: String(item.graceDays),
            createdAt: String(item.createdAt),
            reviewerText: item.reviewer,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationClaimViews(_ items: [RevocationClaim]) -> [RevocationClaimView] {
        var views: [RevocationClaimView] = []
        for item in items {
            views.append(toRevocationClaimView(item))
        }
        return views
    }

    static func sumRevocationClaimView(_ view: RevocationClaimView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRevision) + Double(parsedAcuity) + Double(parsedGraceDays)
    }
}
