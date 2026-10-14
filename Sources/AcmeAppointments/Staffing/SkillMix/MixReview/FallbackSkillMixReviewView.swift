import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback skill mix review.
    final class FallbackSkillMixReviewView {
        var code: String
        var name: String
        var durationMinutes: String
        var refillsText: String
        var scoreText: String
        var capacity: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, refillsText: String, scoreText: String, capacity: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.refillsText = refillsText
            self.scoreText = scoreText
            self.capacity = capacity
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSkillMixReviewView(_ item: FallbackSkillMixReview) -> FallbackSkillMixReviewView {
        return FallbackSkillMixReviewView(
            code: item.code,
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            refillsText: String(item.refills),
            scoreText: String(format: "%.2f", item.score),
            capacity: String(item.capacity),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSkillMixReviewViews(_ items: [FallbackSkillMixReview]) -> [FallbackSkillMixReviewView] {
        var views: [FallbackSkillMixReviewView] = []
        for item in items {
            views.append(toFallbackSkillMixReviewView(item))
        }
        return views
    }

    static func sumFallbackSkillMixReviewView(_ view: FallbackSkillMixReviewView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedRefills) + parsedScore
    }
}
