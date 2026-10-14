import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer rule.
    final class TransferRuleView {
        var code: String
        var label: String
        var limit: String
        var visitMinutes: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, limit: String, visitMinutes: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toTransferRuleView(_ item: TransferRule) -> TransferRuleView {
        return TransferRuleView(
            code: item.code,
            label: item.label,
            limit: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferRuleViews(_ items: [TransferRule]) -> [TransferRuleView] {
        var views: [TransferRuleView] = []
        for item in items {
            views.append(toTransferRuleView(item))
        }
        return views
    }

    static func sumTransferRuleView(_ view: TransferRuleView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedLimit) + Double(parsedVisitMinutes) + parsedCost
    }
}
