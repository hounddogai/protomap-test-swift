import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched bed board allocation.
    final class BatchedBedBoardAllocationView {
        var code: String
        var label: String
        var dosageMg: String
        var description: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, dosageMg: String, description: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.dosageMg = dosageMg
            self.description = description
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedBedBoardAllocationView(_ item: BatchedBedBoardAllocation) -> BatchedBedBoardAllocationView {
        return BatchedBedBoardAllocationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            description: Kit.Text.truncate(item.description, limit: 40),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedBedBoardAllocationViews(_ items: [BatchedBedBoardAllocation]) -> [BatchedBedBoardAllocationView] {
        var views: [BatchedBedBoardAllocationView] = []
        for item in items {
            views.append(toBatchedBedBoardAllocationView(item))
        }
        return views
    }

    static func sumBatchedBedBoardAllocationView(_ view: BatchedBedBoardAllocationView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
