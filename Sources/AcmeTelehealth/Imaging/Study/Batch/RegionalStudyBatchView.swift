import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional study batch.
    final class RegionalStudyBatchView {
        var code: String
        var label: String
        var payerText: String
        var capacityText: String
        var cost: String
        var batchSize: String
        var revisionText: String
        var windowDays: String
        var procedureCode: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, payerText: String, capacityText: String, cost: String, batchSize: String, revisionText: String, windowDays: String, procedureCode: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payerText = payerText
            self.capacityText = capacityText
            self.cost = cost
            self.batchSize = batchSize
            self.revisionText = revisionText
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStudyBatchView(_ item: RegionalStudyBatch) -> RegionalStudyBatchView {
        return RegionalStudyBatchView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            capacityText: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            batchSize: String(item.batchSize),
            revisionText: String(item.revision),
            windowDays: String(item.windowDays),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStudyBatchViews(_ items: [RegionalStudyBatch]) -> [RegionalStudyBatchView] {
        var views: [RegionalStudyBatchView] = []
        for item in items {
            views.append(toRegionalStudyBatchView(item))
        }
        return views
    }

    static func sumRegionalStudyBatchView(_ view: RegionalStudyBatchView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedCapacity) + parsedCost + Double(parsedBatchSize)
    }
}
