import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score entry.
    final class RiskScoreEntryView {
        var code: String
        var title: String
        var discount: String
        var channel: String
        var summary: String
        var limit: String
        var score: String
        var startsAtText: String
        var reviewerText: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, discount: String, channel: String, summary: String, limit: String, score: String, startsAtText: String, reviewerText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.channel = channel
            self.summary = summary
            self.limit = limit
            self.score = score
            self.startsAtText = startsAtText
            self.reviewerText = reviewerText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreEntryView(_ item: RiskScoreEntry) -> RiskScoreEntryView {
        return RiskScoreEntryView(
            code: item.code,
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            summary: item.summary,
            limit: String(item.limit),
            score: String(format: "%.2f", item.score),
            startsAtText: String(item.startsAt),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 80),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreEntryViews(_ items: [RiskScoreEntry]) -> [RiskScoreEntryView] {
        var views: [RiskScoreEntryView] = []
        for item in items {
            views.append(toRiskScoreEntryView(item))
        }
        return views
    }

    static func sumRiskScoreEntryView(_ view: RiskScoreEntryView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedDiscount + Double(parsedLimit) + parsedScore
    }
}
