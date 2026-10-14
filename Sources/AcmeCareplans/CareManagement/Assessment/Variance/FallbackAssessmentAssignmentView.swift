import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback assessment assignment.
    final class FallbackAssessmentAssignmentView {
        var code: String
        var title: String
        var ratio: String
        var score: String
        var createdAt: String
        var weight: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, ratio: String, score: String, createdAt: String, weight: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.score = score
            self.createdAt = createdAt
            self.weight = weight
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAssessmentAssignmentView(_ item: FallbackAssessmentAssignment) -> FallbackAssessmentAssignmentView {
        return FallbackAssessmentAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            score: String(format: "%.2f", item.score),
            createdAt: String(item.createdAt),
            weight: String(format: "%.2f", item.weight),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAssessmentAssignmentViews(_ items: [FallbackAssessmentAssignment]) -> [FallbackAssessmentAssignmentView] {
        var views: [FallbackAssessmentAssignmentView] = []
        for item in items {
            views.append(toFallbackAssessmentAssignmentView(item))
        }
        return views
    }

    static func sumFallbackAssessmentAssignmentView(_ view: FallbackAssessmentAssignmentView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedRatio + parsedScore + Double(parsedCreatedAt)
    }
}
