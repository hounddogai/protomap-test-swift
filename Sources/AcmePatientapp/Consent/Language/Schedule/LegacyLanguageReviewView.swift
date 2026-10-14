import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy language review.
    final class LegacyLanguageReviewView {
        var code: String
        var name: String
        var windowDays: String
        var descriptionText: String
        var unit: String
        var limit: String
        var archived: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, descriptionText: String, unit: String, limit: String, archived: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.descriptionText = descriptionText
            self.unit = unit
            self.limit = limit
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyLanguageReviewView(_ item: LegacyLanguageReview) -> LegacyLanguageReviewView {
        return LegacyLanguageReviewView(
            code: item.code,
            name: item.name,
            windowDays: String(item.windowDays),
            descriptionText: item.description,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            limit: String(item.limit),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyLanguageReviewViews(_ items: [LegacyLanguageReview]) -> [LegacyLanguageReviewView] {
        var views: [LegacyLanguageReviewView] = []
        for item in items {
            views.append(toLegacyLanguageReviewView(item))
        }
        return views
    }

    static func sumLegacyLanguageReviewView(_ view: LegacyLanguageReviewView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedLimit)
    }
}
