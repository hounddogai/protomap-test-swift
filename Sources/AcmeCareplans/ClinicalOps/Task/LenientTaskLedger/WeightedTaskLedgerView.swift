import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted task ledger.
    final class WeightedTaskLedgerView {
        var code: String
        var title: String
        var cost: String
        var approved: String
        var notes: String
        var pinnedText: String
        var visibleText: String
        var channelText: String
        var statusLabel: String

        init(code: String, title: String, cost: String, approved: String, notes: String, pinnedText: String, visibleText: String, channelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.approved = approved
            self.notes = notes
            self.pinnedText = pinnedText
            self.visibleText = visibleText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTaskLedgerView(_ item: WeightedTaskLedger) -> WeightedTaskLedgerView {
        return WeightedTaskLedgerView(
            code: item.code,
            title: item.title,
            cost: String(format: "%.2f", item.cost),
            approved: "\(item.approved)",
            notes: item.notes,
            pinnedText: "\(item.pinned)",
            visibleText: "\(item.visible)",
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTaskLedgerViews(_ items: [WeightedTaskLedger]) -> [WeightedTaskLedgerView] {
        var views: [WeightedTaskLedgerView] = []
        for item in items {
            views.append(toWeightedTaskLedgerView(item))
        }
        return views
    }

    static func sumWeightedTaskLedgerView(_ view: WeightedTaskLedgerView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
