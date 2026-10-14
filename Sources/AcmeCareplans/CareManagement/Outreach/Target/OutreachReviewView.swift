import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach review.
    final class OutreachReviewView {
        var code: String
        var titleText: String
        var revisionText: String
        var category: String
        var pinned: String
        var clinicianID: String
        var updatedAt: String
        var country: String
        var reviewer: String
        var refills: String
        var description: String
        var statusLabel: String

        init(code: String, titleText: String, revisionText: String, category: String, pinned: String, clinicianID: String, updatedAt: String, country: String, reviewer: String, refills: String, description: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.revisionText = revisionText
            self.category = category
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.country = country
            self.reviewer = reviewer
            self.refills = refills
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachReviewView(_ item: OutreachReview) -> OutreachReviewView {
        return OutreachReviewView(
            code: item.code,
            titleText: item.title,
            revisionText: String(item.revision),
            category: Kit.Text.truncate(item.category, limit: 40),
            pinned: "\(item.pinned)",
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            updatedAt: String(item.updatedAt),
            country: item.country,
            reviewer: item.reviewer,
            refills: String(item.refills),
            description: Kit.Text.truncate(item.description, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachReviewViews(_ items: [OutreachReview]) -> [OutreachReviewView] {
        var views: [OutreachReviewView] = []
        for item in items {
            views.append(toOutreachReviewView(item))
        }
        return views
    }

    static func sumOutreachReviewView(_ view: OutreachReviewView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRevision) + Double(parsedUpdatedAt) + Double(parsedRefills)
    }
}
