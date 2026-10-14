import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched slot snapshot.
    final class BatchedSlotSnapshotView {
        var code: String
        var titleText: String
        var priority: String
        var channel: String
        var visible: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, priority: String, channel: String, visible: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.priority = priority
            self.channel = channel
            self.visible = visible
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSlotSnapshotView(_ item: BatchedSlotSnapshot) -> BatchedSlotSnapshotView {
        return BatchedSlotSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            priority: String(item.priority),
            channel: item.channel,
            visible: "\(item.visible)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSlotSnapshotViews(_ items: [BatchedSlotSnapshot]) -> [BatchedSlotSnapshotView] {
        var views: [BatchedSlotSnapshotView] = []
        for item in items {
            views.append(toBatchedSlotSnapshotView(item))
        }
        return views
    }

    static func sumBatchedSlotSnapshotView(_ view: BatchedSlotSnapshotView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedPriority) + parsedAmount
    }
}
