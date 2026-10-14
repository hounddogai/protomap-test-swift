import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback interaction digest.
    final class FallbackInteractionDigestView {
        var code: String
        var nameText: String
        var batchSize: String
        var summaryText: String
        var notesText: String
        var discount: String
        var limit: String
        var unit: String
        var externalRef: String
        var statusLabel: String

        init(code: String, nameText: String, batchSize: String, summaryText: String, notesText: String, discount: String, limit: String, unit: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.batchSize = batchSize
            self.summaryText = summaryText
            self.notesText = notesText
            self.discount = discount
            self.limit = limit
            self.unit = unit
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackInteractionDigestView(_ item: FallbackInteractionDigest) -> FallbackInteractionDigestView {
        return FallbackInteractionDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            batchSize: String(item.batchSize),
            summaryText: item.summary,
            notesText: item.notes,
            discount: String(format: "%.2f", item.discount),
            limit: String(item.limit),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackInteractionDigestViews(_ items: [FallbackInteractionDigest]) -> [FallbackInteractionDigestView] {
        var views: [FallbackInteractionDigestView] = []
        for item in items {
            views.append(toFallbackInteractionDigestView(item))
        }
        return views
    }

    static func sumFallbackInteractionDigestView(_ view: FallbackInteractionDigestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedBatchSize) + parsedDiscount + Double(parsedLimit)
    }
}
