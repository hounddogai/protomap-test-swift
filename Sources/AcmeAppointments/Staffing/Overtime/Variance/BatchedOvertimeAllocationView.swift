import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched overtime allocation.
    final class BatchedOvertimeAllocationView {
        var code: String
        var titleText: String
        var createdAt: String
        var weightText: String
        var floorValueText: String
        var endsAtText: String
        var active: String
        var version: String
        var capacity: String
        var payerText: String
        var statusLabel: String

        init(code: String, titleText: String, createdAt: String, weightText: String, floorValueText: String, endsAtText: String, active: String, version: String, capacity: String, payerText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.createdAt = createdAt
            self.weightText = weightText
            self.floorValueText = floorValueText
            self.endsAtText = endsAtText
            self.active = active
            self.version = version
            self.capacity = capacity
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedOvertimeAllocationView(_ item: BatchedOvertimeAllocation) -> BatchedOvertimeAllocationView {
        return BatchedOvertimeAllocationView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            createdAt: String(item.createdAt),
            weightText: String(format: "%.2f", item.weight),
            floorValueText: String(format: "%.2f", item.floorValue),
            endsAtText: String(item.endsAt),
            active: "\(item.active)",
            version: String(item.version),
            capacity: String(item.capacity),
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedOvertimeAllocationViews(_ items: [BatchedOvertimeAllocation]) -> [BatchedOvertimeAllocationView] {
        var views: [BatchedOvertimeAllocationView] = []
        for item in items {
            views.append(toBatchedOvertimeAllocationView(item))
        }
        return views
    }

    static func sumBatchedOvertimeAllocationView(_ view: BatchedOvertimeAllocationView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedCreatedAt) + parsedWeight + parsedFloorValue
    }
}
