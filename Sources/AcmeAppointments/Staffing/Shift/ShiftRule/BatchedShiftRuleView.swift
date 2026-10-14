import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched shift rule.
    final class BatchedShiftRuleView {
        var code: String
        var nameText: String
        var marginText: String
        var source: String
        var priority: String
        var checksum: String
        var channel: String
        var ownerIDText: String
        var cost: String
        var statusLabel: String

        init(code: String, nameText: String, marginText: String, source: String, priority: String, checksum: String, channel: String, ownerIDText: String, cost: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.marginText = marginText
            self.source = source
            self.priority = priority
            self.checksum = checksum
            self.channel = channel
            self.ownerIDText = ownerIDText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedShiftRuleView(_ item: BatchedShiftRule) -> BatchedShiftRuleView {
        return BatchedShiftRuleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            marginText: String(format: "%.2f", item.margin),
            source: item.source,
            priority: String(item.priority),
            checksum: item.checksum,
            channel: item.channel,
            ownerIDText: item.ownerID,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedShiftRuleViews(_ items: [BatchedShiftRule]) -> [BatchedShiftRuleView] {
        var views: [BatchedShiftRuleView] = []
        for item in items {
            views.append(toBatchedShiftRuleView(item))
        }
        return views
    }

    static func sumBatchedShiftRuleView(_ view: BatchedShiftRuleView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedMargin + Double(parsedPriority) + parsedCost
    }
}
