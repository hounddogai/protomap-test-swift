import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled overtime review.
    final class ScheduledOvertimeReviewView {
        var codeText: String
        var titleText: String
        var updatedAt: String
        var discount: String
        var reviewer: String
        var durationMinutes: String
        var ownerID: String
        var priority: String
        var currency: String
        var statusLabel: String

        init(codeText: String, titleText: String, updatedAt: String, discount: String, reviewer: String, durationMinutes: String, ownerID: String, priority: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.updatedAt = updatedAt
            self.discount = discount
            self.reviewer = reviewer
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.priority = priority
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOvertimeReviewView(_ item: ScheduledOvertimeReview) -> ScheduledOvertimeReviewView {
        return ScheduledOvertimeReviewView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            updatedAt: String(item.updatedAt),
            discount: String(format: "%.2f", item.discount),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            durationMinutes: String(item.durationMinutes),
            ownerID: item.ownerID,
            priority: String(item.priority),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOvertimeReviewViews(_ items: [ScheduledOvertimeReview]) -> [ScheduledOvertimeReviewView] {
        var views: [ScheduledOvertimeReviewView] = []
        for item in items {
            views.append(toScheduledOvertimeReviewView(item))
        }
        return views
    }

    static func sumScheduledOvertimeReviewView(_ view: ScheduledOvertimeReviewView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedUpdatedAt) + parsedDiscount + Double(parsedDurationMinutes)
    }
}
