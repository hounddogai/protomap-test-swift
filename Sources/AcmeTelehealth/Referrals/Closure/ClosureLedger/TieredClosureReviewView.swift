import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered closure review.
    final class TieredClosureReviewView {
        var code: String
        var name: String
        var revision: String
        var activeText: String
        var expiresAtText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, revision: String, activeText: String, expiresAtText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.activeText = activeText
            self.expiresAtText = expiresAtText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredClosureReviewView(_ item: TieredClosureReview) -> TieredClosureReviewView {
        return TieredClosureReviewView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 40),
            revision: String(item.revision),
            activeText: "\(item.active)",
            expiresAtText: String(item.expiresAt),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredClosureReviewViews(_ items: [TieredClosureReview]) -> [TieredClosureReviewView] {
        var views: [TieredClosureReviewView] = []
        for item in items {
            views.append(toTieredClosureReviewView(item))
        }
        return views
    }

    static func sumTieredClosureReviewView(_ view: TieredClosureReviewView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedRevision) + Double(parsedExpiresAt) + Double(parsedCreatedAt)
    }
}
