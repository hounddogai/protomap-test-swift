import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a pending census review.
    final class PendingCensusReviewView {
        var code: String
        var title: String
        var labelText: String
        var refillsText: String
        var unitText: String
        var cost: String
        var reviewer: String
        var category: String
        var locale: String
        var score: String
        var channelText: String
        var statusLabel: String

        init(code: String, title: String, labelText: String, refillsText: String, unitText: String, cost: String, reviewer: String, category: String, locale: String, score: String, channelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.labelText = labelText
            self.refillsText = refillsText
            self.unitText = unitText
            self.cost = cost
            self.reviewer = reviewer
            self.category = category
            self.locale = locale
            self.score = score
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingCensusReviewView(_ item: PendingCensusReview) -> PendingCensusReviewView {
        return PendingCensusReviewView(
            code: item.code,
            title: item.title,
            labelText: item.label,
            refillsText: String(item.refills),
            unitText: item.unit,
            cost: String(format: "%.2f", item.cost),
            reviewer: item.reviewer,
            category: item.category,
            locale: Kit.Text.truncate(item.locale, limit: 64),
            score: String(format: "%.2f", item.score),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingCensusReviewViews(_ items: [PendingCensusReview]) -> [PendingCensusReviewView] {
        var views: [PendingCensusReviewView] = []
        for item in items {
            views.append(toPendingCensusReviewView(item))
        }
        return views
    }

    static func sumPendingCensusReviewView(_ view: PendingCensusReviewView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRefills) + parsedCost + parsedScore
    }
}
