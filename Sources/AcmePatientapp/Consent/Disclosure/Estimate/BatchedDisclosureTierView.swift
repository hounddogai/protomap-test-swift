import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched disclosure tier.
    final class BatchedDisclosureTierView {
        var code: String
        var title: String
        var revisionText: String
        var source: String
        var retriesText: String
        var pinned: String
        var startsAtText: String
        var amount: String
        var windowDays: String
        var statusLabel: String

        init(code: String, title: String, revisionText: String, source: String, retriesText: String, pinned: String, startsAtText: String, amount: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revisionText = revisionText
            self.source = source
            self.retriesText = retriesText
            self.pinned = pinned
            self.startsAtText = startsAtText
            self.amount = amount
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDisclosureTierView(_ item: BatchedDisclosureTier) -> BatchedDisclosureTierView {
        return BatchedDisclosureTierView(
            code: item.code,
            title: item.title,
            revisionText: String(item.revision),
            source: item.source,
            retriesText: String(item.retries),
            pinned: "\(item.pinned)",
            startsAtText: String(item.startsAt),
            amount: String(format: "%.2f", item.amount),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDisclosureTierViews(_ items: [BatchedDisclosureTier]) -> [BatchedDisclosureTierView] {
        var views: [BatchedDisclosureTierView] = []
        for item in items {
            views.append(toBatchedDisclosureTierView(item))
        }
        return views
    }

    static func sumBatchedDisclosureTierView(_ view: BatchedDisclosureTierView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRevision) + Double(parsedRetries) + Double(parsedStartsAt)
    }
}
