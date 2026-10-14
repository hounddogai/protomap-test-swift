import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped denial manifest.
    final class CappedDenialManifestView {
        var codeText: String
        var labelText: String
        var currency: String
        var channelText: String
        var summary: String
        var quantity: String
        var categoryText: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, labelText: String, currency: String, channelText: String, summary: String, quantity: String, categoryText: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.currency = currency
            self.channelText = channelText
            self.summary = summary
            self.quantity = quantity
            self.categoryText = categoryText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDenialManifestView(_ item: CappedDenialManifest) -> CappedDenialManifestView {
        return CappedDenialManifestView(
            codeText: item.code,
            labelText: item.label,
            currency: item.currency,
            channelText: item.channel,
            summary: item.summary,
            quantity: String(item.quantity),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDenialManifestViews(_ items: [CappedDenialManifest]) -> [CappedDenialManifestView] {
        var views: [CappedDenialManifestView] = []
        for item in items {
            views.append(toCappedDenialManifestView(item))
        }
        return views
    }

    static func sumCappedDenialManifestView(_ view: CappedDenialManifestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedQuantity) + Double(parsedSequence)
    }
}
