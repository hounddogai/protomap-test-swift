import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a capped modality batch.
    final class CappedModalityBatchView {
        var codeText: String
        var name: String
        var channel: String
        var updatedAtText: String
        var allergy: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, name: String, channel: String, updatedAtText: String, allergy: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.channel = channel
            self.updatedAtText = updatedAtText
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedModalityBatchView(_ item: CappedModalityBatch) -> CappedModalityBatchView {
        return CappedModalityBatchView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 120),
            channel: item.channel,
            updatedAtText: String(item.updatedAt),
            allergy: item.allergy,
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedModalityBatchViews(_ items: [CappedModalityBatch]) -> [CappedModalityBatchView] {
        var views: [CappedModalityBatchView] = []
        for item in items {
            views.append(toCappedModalityBatchView(item))
        }
        return views
    }

    static func sumCappedModalityBatchView(_ view: CappedModalityBatchView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedExpiresAt)
    }
}
