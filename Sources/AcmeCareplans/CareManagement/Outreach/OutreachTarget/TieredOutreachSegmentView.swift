import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered outreach segment.
    final class TieredOutreachSegmentView {
        var code: String
        var label: String
        var startsAtText: String
        var refills: String
        var amountText: String
        var discount: String
        var reviewerText: String
        var summaryText: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, startsAtText: String, refills: String, amountText: String, discount: String, reviewerText: String, summaryText: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.startsAtText = startsAtText
            self.refills = refills
            self.amountText = amountText
            self.discount = discount
            self.reviewerText = reviewerText
            self.summaryText = summaryText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOutreachSegmentView(_ item: TieredOutreachSegment) -> TieredOutreachSegmentView {
        return TieredOutreachSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            startsAtText: String(item.startsAt),
            refills: String(item.refills),
            amountText: String(format: "%.2f", item.amount),
            discount: String(format: "%.2f", item.discount),
            reviewerText: item.reviewer,
            summaryText: item.summary,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOutreachSegmentViews(_ items: [TieredOutreachSegment]) -> [TieredOutreachSegmentView] {
        var views: [TieredOutreachSegmentView] = []
        for item in items {
            views.append(toTieredOutreachSegmentView(item))
        }
        return views
    }

    static func sumTieredOutreachSegmentView(_ view: TieredOutreachSegmentView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRefills) + parsedAmount
    }
}
