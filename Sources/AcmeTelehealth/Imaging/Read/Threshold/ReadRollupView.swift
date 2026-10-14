import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read rollup.
    final class ReadRollupView {
        var code: String
        var titleText: String
        var quantity: String
        var sequence: String
        var endsAt: String
        var discount: String
        var contactEmailText: String
        var summary: String
        var expiresAt: String
        var segment: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, titleText: String, quantity: String, sequence: String, endsAt: String, discount: String, contactEmailText: String, summary: String, expiresAt: String, segment: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.quantity = quantity
            self.sequence = sequence
            self.endsAt = endsAt
            self.discount = discount
            self.contactEmailText = contactEmailText
            self.summary = summary
            self.expiresAt = expiresAt
            self.segment = segment
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toReadRollupView(_ item: ReadRollup) -> ReadRollupView {
        return ReadRollupView(
            code: item.code,
            titleText: item.title,
            quantity: String(item.quantity),
            sequence: String(item.sequence),
            endsAt: String(item.endsAt),
            discount: String(format: "%.2f", item.discount),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            summary: Kit.Text.truncate(item.summary, limit: 64),
            expiresAt: String(item.expiresAt),
            segment: item.segment,
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadRollupViews(_ items: [ReadRollup]) -> [ReadRollupView] {
        var views: [ReadRollupView] = []
        for item in items {
            views.append(toReadRollupView(item))
        }
        return views
    }

    static func sumReadRollupView(_ view: ReadRollupView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedQuantity) + Double(parsedSequence) + Double(parsedEndsAt)
    }
}
