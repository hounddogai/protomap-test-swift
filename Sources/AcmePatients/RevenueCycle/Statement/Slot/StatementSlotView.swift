import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement slot.
    final class StatementSlotView {
        var codeText: String
        var label: String
        var cost: String
        var version: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, label: String, cost: String, version: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.cost = cost
            self.version = version
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toStatementSlotView(_ item: StatementSlot) -> StatementSlotView {
        return StatementSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            cost: String(format: "%.2f", item.cost),
            version: String(item.version),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementSlotViews(_ items: [StatementSlot]) -> [StatementSlotView] {
        var views: [StatementSlotView] = []
        for item in items {
            views.append(toStatementSlotView(item))
        }
        return views
    }

    static func sumStatementSlotView(_ view: StatementSlotView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCost + Double(parsedVersion) + parsedThreshold
    }
}
