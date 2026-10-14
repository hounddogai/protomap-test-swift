import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form review.
    final class RollingConsentFormReviewView {
        var code: String
        var titleText: String
        var contactEmail: String
        var windowDays: String
        var ownerID: String
        var quantity: String
        var category: String
        var priorityText: String
        var statusLabel: String

        init(code: String, titleText: String, contactEmail: String, windowDays: String, ownerID: String, quantity: String, category: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.contactEmail = contactEmail
            self.windowDays = windowDays
            self.ownerID = ownerID
            self.quantity = quantity
            self.category = category
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormReviewView(_ item: RollingConsentFormReview) -> RollingConsentFormReviewView {
        return RollingConsentFormReviewView(
            code: item.code,
            titleText: item.title,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            windowDays: String(item.windowDays),
            ownerID: item.ownerID,
            quantity: String(item.quantity),
            category: item.category,
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormReviewViews(_ items: [RollingConsentFormReview]) -> [RollingConsentFormReviewView] {
        var views: [RollingConsentFormReviewView] = []
        for item in items {
            views.append(toRollingConsentFormReviewView(item))
        }
        return views
    }

    static func sumRollingConsentFormReviewView(_ view: RollingConsentFormReviewView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedQuantity) + Double(parsedPriority)
    }
}
