import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped courier review.
    final class CappedCourierReviewView {
        var code: String
        var titleText: String
        var procedureCode: String
        var ratioText: String
        var durationMinutes: String
        var expiresAt: String
        var visitMinutes: String
        var priority: String
        var statusLabel: String

        init(code: String, titleText: String, procedureCode: String, ratioText: String, durationMinutes: String, expiresAt: String, visitMinutes: String, priority: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.procedureCode = procedureCode
            self.ratioText = ratioText
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCourierReviewView(_ item: CappedCourierReview) -> CappedCourierReviewView {
        return CappedCourierReviewView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            procedureCode: item.procedureCode,
            ratioText: String(format: "%.2f", item.ratio),
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            visitMinutes: String(item.visitMinutes),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCourierReviewViews(_ items: [CappedCourierReview]) -> [CappedCourierReviewView] {
        var views: [CappedCourierReviewView] = []
        for item in items {
            views.append(toCappedCourierReviewView(item))
        }
        return views
    }

    static func sumCappedCourierReviewView(_ view: CappedCourierReviewView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedRatio + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
