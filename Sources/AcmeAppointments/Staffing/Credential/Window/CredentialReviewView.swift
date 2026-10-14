import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential review.
    final class CredentialReviewView {
        var code: String
        var title: String
        var region: String
        var revision: String
        var phone: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, region: String, revision: String, phone: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.revision = revision
            self.phone = phone
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialReviewView(_ item: CredentialReview) -> CredentialReviewView {
        return CredentialReviewView(
            code: item.code,
            title: item.title,
            region: Kit.Text.truncate(item.region, limit: 120),
            revision: String(item.revision),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialReviewViews(_ items: [CredentialReview]) -> [CredentialReviewView] {
        var views: [CredentialReviewView] = []
        for item in items {
            views.append(toCredentialReviewView(item))
        }
        return views
    }

    static func sumCredentialReviewView(_ view: CredentialReviewView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedRevision) + Double(parsedEndsAt)
    }
}
