import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional slot review.
    final class RegionalSlotReviewView {
        var code: String
        var title: String
        var encounterID: String
        var attempts: String
        var allergy: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, title: String, encounterID: String, attempts: String, allergy: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.attempts = attempts
            self.allergy = allergy
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSlotReviewView(_ item: RegionalSlotReview) -> RegionalSlotReviewView {
        return RegionalSlotReviewView(
            code: item.code,
            title: item.title,
            encounterID: item.encounterID,
            attempts: String(item.attempts),
            allergy: item.allergy,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSlotReviewViews(_ items: [RegionalSlotReview]) -> [RegionalSlotReviewView] {
        var views: [RegionalSlotReviewView] = []
        for item in items {
            views.append(toRegionalSlotReviewView(item))
        }
        return views
    }

    static func sumRegionalSlotReviewView(_ view: RegionalSlotReviewView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
