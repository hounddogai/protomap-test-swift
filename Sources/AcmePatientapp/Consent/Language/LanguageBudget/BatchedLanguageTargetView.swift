import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched language target.
    final class BatchedLanguageTargetView {
        var code: String
        var label: String
        var channel: String
        var maximum: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, label: String, channel: String, maximum: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.maximum = maximum
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedLanguageTargetView(_ item: BatchedLanguageTarget) -> BatchedLanguageTargetView {
        return BatchedLanguageTargetView(
            code: item.code,
            label: item.label,
            channel: Kit.Text.truncate(item.channel, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedLanguageTargetViews(_ items: [BatchedLanguageTarget]) -> [BatchedLanguageTargetView] {
        var views: [BatchedLanguageTargetView] = []
        for item in items {
            views.append(toBatchedLanguageTargetView(item))
        }
        return views
    }

    static func sumBatchedLanguageTargetView(_ view: BatchedLanguageTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt)
    }
}
