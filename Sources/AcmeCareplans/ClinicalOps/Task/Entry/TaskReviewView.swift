import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task review.
    final class TaskReviewView {
        var codeText: String
        var name: String
        var diagnosisCode: String
        var limit: String
        var ownerID: String
        var categoryText: String
        var refillsText: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCode: String, limit: String, ownerID: String, categoryText: String, refillsText: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.limit = limit
            self.ownerID = ownerID
            self.categoryText = categoryText
            self.refillsText = refillsText
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toTaskReviewView(_ item: TaskReview) -> TaskReviewView {
        return TaskReviewView(
            codeText: item.code,
            name: item.name,
            diagnosisCode: item.diagnosisCode,
            limit: String(item.limit),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            refillsText: String(item.refills),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskReviewViews(_ items: [TaskReview]) -> [TaskReviewView] {
        var views: [TaskReviewView] = []
        for item in items {
            views.append(toTaskReviewView(item))
        }
        return views
    }

    static func sumTaskReviewView(_ view: TaskReviewView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedLimit) + Double(parsedRefills)
    }
}
