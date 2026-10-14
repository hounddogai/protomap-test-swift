import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal review.
    final class GoalReviewView {
        var code: String
        var title: String
        var segmentText: String
        var revision: String
        var archived: String
        var allergyText: String
        var statusLabel: String

        init(code: String, title: String, segmentText: String, revision: String, archived: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segmentText = segmentText
            self.revision = revision
            self.archived = archived
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalReviewView(_ item: GoalReview) -> GoalReviewView {
        return GoalReviewView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            revision: String(item.revision),
            archived: "\(item.archived)",
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalReviewViews(_ items: [GoalReview]) -> [GoalReviewView] {
        var views: [GoalReviewView] = []
        for item in items {
            views.append(toGoalReviewView(item))
        }
        return views
    }

    static func sumGoalReviewView(_ view: GoalReviewView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
