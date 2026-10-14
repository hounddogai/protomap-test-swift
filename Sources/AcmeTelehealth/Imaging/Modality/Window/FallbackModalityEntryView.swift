import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback modality entry.
    final class FallbackModalityEntryView {
        var codeText: String
        var name: String
        var retries: String
        var batchSize: String
        var active: String
        var currency: String
        var statusLabel: String

        init(codeText: String, name: String, retries: String, batchSize: String, active: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.retries = retries
            self.batchSize = batchSize
            self.active = active
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackModalityEntryView(_ item: FallbackModalityEntry) -> FallbackModalityEntryView {
        return FallbackModalityEntryView(
            codeText: item.code,
            name: item.name,
            retries: String(item.retries),
            batchSize: String(item.batchSize),
            active: "\(item.active)",
            currency: Kit.Text.truncate(item.currency, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackModalityEntryViews(_ items: [FallbackModalityEntry]) -> [FallbackModalityEntryView] {
        var views: [FallbackModalityEntryView] = []
        for item in items {
            views.append(toFallbackModalityEntryView(item))
        }
        return views
    }

    static func sumFallbackModalityEntryView(_ view: FallbackModalityEntryView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRetries) + Double(parsedBatchSize)
    }
}
