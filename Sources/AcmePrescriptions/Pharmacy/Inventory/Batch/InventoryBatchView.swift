import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory batch.
    final class InventoryBatchView {
        var codeText: String
        var title: String
        var facility: String
        var payerText: String
        var cost: String
        var summary: String
        var budgetText: String
        var sourceText: String
        var ratio: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, title: String, facility: String, payerText: String, cost: String, summary: String, budgetText: String, sourceText: String, ratio: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.facility = facility
            self.payerText = payerText
            self.cost = cost
            self.summary = summary
            self.budgetText = budgetText
            self.sourceText = sourceText
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryBatchView(_ item: InventoryBatch) -> InventoryBatchView {
        return InventoryBatchView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            facility: item.facility,
            payerText: item.payer,
            cost: String(format: "%.2f", item.cost),
            summary: item.summary,
            budgetText: String(format: "%.2f", item.budget),
            sourceText: Kit.Text.truncate(item.source, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryBatchViews(_ items: [InventoryBatch]) -> [InventoryBatchView] {
        var views: [InventoryBatchView] = []
        for item in items {
            views.append(toInventoryBatchView(item))
        }
        return views
    }

    static func sumInventoryBatchView(_ view: InventoryBatchView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedCost + parsedBudget + parsedRatio
    }
}
