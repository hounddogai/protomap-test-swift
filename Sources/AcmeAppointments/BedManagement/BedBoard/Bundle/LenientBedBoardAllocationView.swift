import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient bed board allocation.
    final class LenientBedBoardAllocationView {
        var code: String
        var labelText: String
        var priority: String
        var countryText: String
        var batchSize: String
        var approved: String
        var createdAt: String
        var statusLabel: String

        init(code: String, labelText: String, priority: String, countryText: String, batchSize: String, approved: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priority = priority
            self.countryText = countryText
            self.batchSize = batchSize
            self.approved = approved
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toLenientBedBoardAllocationView(_ item: LenientBedBoardAllocation) -> LenientBedBoardAllocationView {
        return LenientBedBoardAllocationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            priority: String(item.priority),
            countryText: Kit.Text.truncate(item.country, limit: 120),
            batchSize: String(item.batchSize),
            approved: "\(item.approved)",
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientBedBoardAllocationViews(_ items: [LenientBedBoardAllocation]) -> [LenientBedBoardAllocationView] {
        var views: [LenientBedBoardAllocationView] = []
        for item in items {
            views.append(toLenientBedBoardAllocationView(item))
        }
        return views
    }

    static func sumLenientBedBoardAllocationView(_ view: LenientBedBoardAllocationView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + Double(parsedBatchSize) + Double(parsedCreatedAt)
    }
}
