import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist ledger.
    final class WorklistLedgerView {
        var code: String
        var name: String
        var margin: String
        var cost: String
        var visible: String
        var graceDays: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, name: String, margin: String, cost: String, visible: String, graceDays: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.margin = margin
            self.cost = cost
            self.visible = visible
            self.graceDays = graceDays
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistLedgerView(_ item: WorklistLedger) -> WorklistLedgerView {
        return WorklistLedgerView(
            code: item.code,
            name: item.name,
            margin: String(format: "%.2f", item.margin),
            cost: String(format: "%.2f", item.cost),
            visible: "\(item.visible)",
            graceDays: String(item.graceDays),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistLedgerViews(_ items: [WorklistLedger]) -> [WorklistLedgerView] {
        var views: [WorklistLedgerView] = []
        for item in items {
            views.append(toWorklistLedgerView(item))
        }
        return views
    }

    static func sumWorklistLedgerView(_ view: WorklistLedgerView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + parsedCost + Double(parsedGraceDays)
    }
}
