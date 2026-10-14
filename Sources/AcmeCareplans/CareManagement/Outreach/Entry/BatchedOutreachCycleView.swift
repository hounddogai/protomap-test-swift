import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched outreach cycle.
    final class BatchedOutreachCycleView {
        var code: String
        var title: String
        var batchSize: String
        var nameText: String
        var encounterID: String
        var clinicianID: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, batchSize: String, nameText: String, encounterID: String, clinicianID: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.nameText = nameText
            self.encounterID = encounterID
            self.clinicianID = clinicianID
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOutreachCycleView(_ item: BatchedOutreachCycle) -> BatchedOutreachCycleView {
        return BatchedOutreachCycleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            batchSize: String(item.batchSize),
            nameText: item.name,
            encounterID: item.encounterID,
            clinicianID: item.clinicianID,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOutreachCycleViews(_ items: [BatchedOutreachCycle]) -> [BatchedOutreachCycleView] {
        var views: [BatchedOutreachCycleView] = []
        for item in items {
            views.append(toBatchedOutreachCycleView(item))
        }
        return views
    }

    static func sumBatchedOutreachCycleView(_ view: BatchedOutreachCycleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedBatchSize) + parsedDiscount
    }
}
