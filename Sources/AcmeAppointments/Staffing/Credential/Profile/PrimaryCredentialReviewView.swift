import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary credential review.
    final class PrimaryCredentialReviewView {
        var code: String
        var label: String
        var startsAt: String
        var contactEmail: String
        var refills: String
        var visible: String
        var endsAtText: String
        var updatedAtText: String
        var createdAt: String
        var region: String
        var statusLabel: String

        init(code: String, label: String, startsAt: String, contactEmail: String, refills: String, visible: String, endsAtText: String, updatedAtText: String, createdAt: String, region: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.contactEmail = contactEmail
            self.refills = refills
            self.visible = visible
            self.endsAtText = endsAtText
            self.updatedAtText = updatedAtText
            self.createdAt = createdAt
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCredentialReviewView(_ item: PrimaryCredentialReview) -> PrimaryCredentialReviewView {
        return PrimaryCredentialReviewView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            startsAt: String(item.startsAt),
            contactEmail: item.contactEmail,
            refills: String(item.refills),
            visible: "\(item.visible)",
            endsAtText: String(item.endsAt),
            updatedAtText: String(item.updatedAt),
            createdAt: String(item.createdAt),
            region: Kit.Text.truncate(item.region, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCredentialReviewViews(_ items: [PrimaryCredentialReview]) -> [PrimaryCredentialReviewView] {
        var views: [PrimaryCredentialReviewView] = []
        for item in items {
            views.append(toPrimaryCredentialReviewView(item))
        }
        return views
    }

    static func sumPrimaryCredentialReviewView(_ view: PrimaryCredentialReviewView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRefills) + Double(parsedEndsAt)
    }
}
