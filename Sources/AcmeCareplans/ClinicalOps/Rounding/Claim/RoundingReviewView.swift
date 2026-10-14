import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding review.
    final class RoundingReviewView {
        var code: String
        var title: String
        var segment: String
        var revisionText: String
        var unit: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, segment: String, revisionText: String, unit: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.revisionText = revisionText
            self.unit = unit
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingReviewView(_ item: RoundingReview) -> RoundingReviewView {
        return RoundingReviewView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            segment: Kit.Text.truncate(item.segment, limit: 40),
            revisionText: String(item.revision),
            unit: item.unit,
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingReviewViews(_ items: [RoundingReview]) -> [RoundingReviewView] {
        var views: [RoundingReviewView] = []
        for item in items {
            views.append(toRoundingReviewView(item))
        }
        return views
    }

    static func sumRoundingReviewView(_ view: RoundingReviewView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
