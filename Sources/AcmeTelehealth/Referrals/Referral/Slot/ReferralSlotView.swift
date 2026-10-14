import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral slot.
    final class ReferralSlotView {
        var code: String
        var titleText: String
        var segment: String
        var summary: String
        var externalRef: String
        var scoreText: String
        var statusLabel: String

        init(code: String, titleText: String, segment: String, summary: String, externalRef: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.segment = segment
            self.summary = summary
            self.externalRef = externalRef
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralSlotView(_ item: ReferralSlot) -> ReferralSlotView {
        return ReferralSlotView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            summary: item.summary,
            externalRef: item.externalRef,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralSlotViews(_ items: [ReferralSlot]) -> [ReferralSlotView] {
        var views: [ReferralSlotView] = []
        for item in items {
            views.append(toReferralSlotView(item))
        }
        return views
    }

    static func sumReferralSlotView(_ view: ReferralSlotView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
