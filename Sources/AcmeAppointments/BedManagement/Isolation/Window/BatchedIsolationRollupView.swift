import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched isolation rollup.
    final class BatchedIsolationRollupView {
        var code: String
        var title: String
        var score: String
        var graceDaysText: String
        var category: String
        var descriptionText: String
        var versionText: String
        var attempts: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, score: String, graceDaysText: String, category: String, descriptionText: String, versionText: String, attempts: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.score = score
            self.graceDaysText = graceDaysText
            self.category = category
            self.descriptionText = descriptionText
            self.versionText = versionText
            self.attempts = attempts
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedIsolationRollupView(_ item: BatchedIsolationRollup) -> BatchedIsolationRollupView {
        return BatchedIsolationRollupView(
            code: item.code,
            title: item.title,
            score: String(format: "%.2f", item.score),
            graceDaysText: String(item.graceDays),
            category: Kit.Text.truncate(item.category, limit: 64),
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            versionText: String(item.version),
            attempts: String(item.attempts),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedIsolationRollupViews(_ items: [BatchedIsolationRollup]) -> [BatchedIsolationRollupView] {
        var views: [BatchedIsolationRollupView] = []
        for item in items {
            views.append(toBatchedIsolationRollupView(item))
        }
        return views
    }

    static func sumBatchedIsolationRollupView(_ view: BatchedIsolationRollupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedScore + Double(parsedGraceDays) + Double(parsedVersion)
    }
}
