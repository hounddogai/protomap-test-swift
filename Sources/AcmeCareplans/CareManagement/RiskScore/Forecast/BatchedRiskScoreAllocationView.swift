import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched risk score allocation.
    final class BatchedRiskScoreAllocationView {
        var codeText: String
        var title: String
        var ownerID: String
        var dosageMg: String
        var updatedAt: String
        var contactEmail: String
        var batchSizeText: String
        var discount: String
        var nameText: String
        var labelText: String
        var statusLabel: String

        init(codeText: String, title: String, ownerID: String, dosageMg: String, updatedAt: String, contactEmail: String, batchSizeText: String, discount: String, nameText: String, labelText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.batchSizeText = batchSizeText
            self.discount = discount
            self.nameText = nameText
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRiskScoreAllocationView(_ item: BatchedRiskScoreAllocation) -> BatchedRiskScoreAllocationView {
        return BatchedRiskScoreAllocationView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            ownerID: item.ownerID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            updatedAt: String(item.updatedAt),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            batchSizeText: String(item.batchSize),
            discount: String(format: "%.2f", item.discount),
            nameText: item.name,
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRiskScoreAllocationViews(_ items: [BatchedRiskScoreAllocation]) -> [BatchedRiskScoreAllocationView] {
        var views: [BatchedRiskScoreAllocationView] = []
        for item in items {
            views.append(toBatchedRiskScoreAllocationView(item))
        }
        return views
    }

    static func sumBatchedRiskScoreAllocationView(_ view: BatchedRiskScoreAllocationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedDosageMg + Double(parsedUpdatedAt) + Double(parsedBatchSize)
    }
}
