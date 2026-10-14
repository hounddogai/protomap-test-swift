import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback dispense review.
    final class FallbackDispenseReviewView {
        var code: String
        var title: String
        var marginText: String
        var name: String
        var label: String
        var scoreText: String
        var refillsText: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, name: String, label: String, scoreText: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.name = name
            self.label = label
            self.scoreText = scoreText
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDispenseReviewView(_ item: FallbackDispenseReview) -> FallbackDispenseReviewView {
        return FallbackDispenseReviewView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            marginText: String(format: "%.2f", item.margin),
            name: item.name,
            label: item.label,
            scoreText: String(format: "%.2f", item.score),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDispenseReviewViews(_ items: [FallbackDispenseReview]) -> [FallbackDispenseReviewView] {
        var views: [FallbackDispenseReviewView] = []
        for item in items {
            views.append(toFallbackDispenseReviewView(item))
        }
        return views
    }

    static func sumFallbackDispenseReviewView(_ view: FallbackDispenseReviewView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMargin + parsedScore + Double(parsedRefills)
    }
}
