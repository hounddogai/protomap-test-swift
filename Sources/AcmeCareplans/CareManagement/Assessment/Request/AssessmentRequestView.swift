import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment request.
    final class AssessmentRequestView {
        var codeText: String
        var title: String
        var updatedAt: String
        var attempts: String
        var procedureCodeText: String
        var summaryText: String
        var score: String
        var version: String
        var statusLabel: String

        init(codeText: String, title: String, updatedAt: String, attempts: String, procedureCodeText: String, summaryText: String, score: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.updatedAt = updatedAt
            self.attempts = attempts
            self.procedureCodeText = procedureCodeText
            self.summaryText = summaryText
            self.score = score
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentRequestView(_ item: AssessmentRequest) -> AssessmentRequestView {
        return AssessmentRequestView(
            codeText: item.code,
            title: item.title,
            updatedAt: String(item.updatedAt),
            attempts: String(item.attempts),
            procedureCodeText: item.procedureCode,
            summaryText: item.summary,
            score: String(format: "%.2f", item.score),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentRequestViews(_ items: [AssessmentRequest]) -> [AssessmentRequestView] {
        var views: [AssessmentRequestView] = []
        for item in items {
            views.append(toAssessmentRequestView(item))
        }
        return views
    }

    static func sumAssessmentRequestView(_ view: AssessmentRequestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedAttempts) + parsedScore
    }
}
