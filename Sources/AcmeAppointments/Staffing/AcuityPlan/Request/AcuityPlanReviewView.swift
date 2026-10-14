import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan review.
    final class AcuityPlanReviewView {
        var code: String
        var name: String
        var timezone: String
        var batchSize: String
        var graceDays: String
        var attempts: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, timezone: String, batchSize: String, graceDays: String, attempts: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.attempts = attempts
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanReviewView(_ item: AcuityPlanReview) -> AcuityPlanReviewView {
        return AcuityPlanReviewView(
            code: item.code,
            name: item.name,
            timezone: item.timezone,
            batchSize: String(item.batchSize),
            graceDays: String(item.graceDays),
            attempts: String(item.attempts),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanReviewViews(_ items: [AcuityPlanReview]) -> [AcuityPlanReviewView] {
        var views: [AcuityPlanReviewView] = []
        for item in items {
            views.append(toAcuityPlanReviewView(item))
        }
        return views
    }

    static func sumAcuityPlanReviewView(_ view: AcuityPlanReviewView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + Double(parsedAttempts)
    }
}
