import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall baseline.
    final class RecallBaselineView {
        var code: String
        var title: String
        var maximum: String
        var phone: String
        var endsAtText: String
        var margin: String
        var ratio: String
        var checksum: String
        var quantity: String
        var scoreText: String
        var approved: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, phone: String, endsAtText: String, margin: String, ratio: String, checksum: String, quantity: String, scoreText: String, approved: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.phone = phone
            self.endsAtText = endsAtText
            self.margin = margin
            self.ratio = ratio
            self.checksum = checksum
            self.quantity = quantity
            self.scoreText = scoreText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toRecallBaselineView(_ item: RecallBaseline) -> RecallBaselineView {
        return RecallBaselineView(
            code: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            endsAtText: String(item.endsAt),
            margin: String(format: "%.2f", item.margin),
            ratio: String(format: "%.2f", item.ratio),
            checksum: item.checksum,
            quantity: String(item.quantity),
            scoreText: String(format: "%.2f", item.score),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallBaselineViews(_ items: [RecallBaseline]) -> [RecallBaselineView] {
        var views: [RecallBaselineView] = []
        for item in items {
            views.append(toRecallBaselineView(item))
        }
        return views
    }

    static func sumRecallBaselineView(_ view: RecallBaselineView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMaximum + Double(parsedEndsAt) + parsedMargin
    }
}
