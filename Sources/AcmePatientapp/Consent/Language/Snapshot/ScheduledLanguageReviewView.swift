import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled language review.
    final class ScheduledLanguageReviewView {
        var code: String
        var labelText: String
        var name: String
        var reviewer: String
        var category: String
        var capacityText: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, labelText: String, name: String, reviewer: String, category: String, capacityText: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.name = name
            self.reviewer = reviewer
            self.category = category
            self.capacityText = capacityText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledLanguageReviewView(_ item: ScheduledLanguageReview) -> ScheduledLanguageReviewView {
        return ScheduledLanguageReviewView(
            code: item.code,
            labelText: item.label,
            name: item.name,
            reviewer: item.reviewer,
            category: item.category,
            capacityText: String(item.capacity),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledLanguageReviewViews(_ items: [ScheduledLanguageReview]) -> [ScheduledLanguageReviewView] {
        var views: [ScheduledLanguageReviewView] = []
        for item in items {
            views.append(toScheduledLanguageReviewView(item))
        }
        return views
    }

    static func sumScheduledLanguageReviewView(_ view: ScheduledLanguageReviewView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
