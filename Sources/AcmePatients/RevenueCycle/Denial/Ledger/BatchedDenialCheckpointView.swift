import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched denial checkpoint.
    final class BatchedDenialCheckpointView {
        var code: String
        var title: String
        var localeText: String
        var country: String
        var windowDays: String
        var sourceText: String
        var statusLabel: String

        init(code: String, title: String, localeText: String, country: String, windowDays: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.localeText = localeText
            self.country = country
            self.windowDays = windowDays
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDenialCheckpointView(_ item: BatchedDenialCheckpoint) -> BatchedDenialCheckpointView {
        return BatchedDenialCheckpointView(
            code: item.code,
            title: item.title,
            localeText: item.locale,
            country: item.country,
            windowDays: String(item.windowDays),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDenialCheckpointViews(_ items: [BatchedDenialCheckpoint]) -> [BatchedDenialCheckpointView] {
        var views: [BatchedDenialCheckpointView] = []
        for item in items {
            views.append(toBatchedDenialCheckpointView(item))
        }
        return views
    }

    static func sumBatchedDenialCheckpointView(_ view: BatchedDenialCheckpointView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
