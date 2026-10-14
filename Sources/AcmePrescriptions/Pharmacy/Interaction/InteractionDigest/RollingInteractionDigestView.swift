import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling interaction digest.
    final class RollingInteractionDigestView {
        var code: String
        var titleText: String
        var externalRef: String
        var threshold: String
        var durationMinutes: String
        var batchSize: String
        var reviewer: String
        var amountText: String
        var score: String
        var notes: String
        var maximum: String
        var statusLabel: String

        init(code: String, titleText: String, externalRef: String, threshold: String, durationMinutes: String, batchSize: String, reviewer: String, amountText: String, score: String, notes: String, maximum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.externalRef = externalRef
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.amountText = amountText
            self.score = score
            self.notes = notes
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toRollingInteractionDigestView(_ item: RollingInteractionDigest) -> RollingInteractionDigestView {
        return RollingInteractionDigestView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            externalRef: item.externalRef,
            threshold: String(format: "%.2f", item.threshold),
            durationMinutes: String(item.durationMinutes),
            batchSize: String(item.batchSize),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            score: String(format: "%.2f", item.score),
            notes: Kit.Text.truncate(item.notes, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingInteractionDigestViews(_ items: [RollingInteractionDigest]) -> [RollingInteractionDigestView] {
        var views: [RollingInteractionDigestView] = []
        for item in items {
            views.append(toRollingInteractionDigestView(item))
        }
        return views
    }

    static func sumRollingInteractionDigestView(_ view: RollingInteractionDigestView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes) + Double(parsedBatchSize)
    }
}
