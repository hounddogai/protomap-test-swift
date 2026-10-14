import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered risk score review.
    final class TieredRiskScoreReviewView {
        var code: String
        var title: String
        var unitText: String
        var marginText: String
        var archivedText: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, unitText: String, marginText: String, archivedText: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unitText = unitText
            self.marginText = marginText
            self.archivedText = archivedText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRiskScoreReviewView(_ item: TieredRiskScoreReview) -> TieredRiskScoreReviewView {
        return TieredRiskScoreReviewView(
            code: item.code,
            title: item.title,
            unitText: item.unit,
            marginText: String(format: "%.2f", item.margin),
            archivedText: "\(item.archived)",
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRiskScoreReviewViews(_ items: [TieredRiskScoreReview]) -> [TieredRiskScoreReviewView] {
        var views: [TieredRiskScoreReviewView] = []
        for item in items {
            views.append(toTieredRiskScoreReviewView(item))
        }
        return views
    }

    static func sumTieredRiskScoreReviewView(_ view: TieredRiskScoreReviewView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedMargin + parsedScore
    }
}
