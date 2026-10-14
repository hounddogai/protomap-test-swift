import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched interaction milestone.
    final class BatchedInteractionMilestoneView {
        var code: String
        var name: String
        var floorValue: String
        var sequence: String
        var unit: String
        var pinned: String
        var weight: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, sequence: String, unit: String, pinned: String, weight: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.sequence = sequence
            self.unit = unit
            self.pinned = pinned
            self.weight = weight
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedInteractionMilestoneView(_ item: BatchedInteractionMilestone) -> BatchedInteractionMilestoneView {
        return BatchedInteractionMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            sequence: String(item.sequence),
            unit: item.unit,
            pinned: "\(item.pinned)",
            weight: String(format: "%.2f", item.weight),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedInteractionMilestoneViews(_ items: [BatchedInteractionMilestone]) -> [BatchedInteractionMilestoneView] {
        var views: [BatchedInteractionMilestoneView] = []
        for item in items {
            views.append(toBatchedInteractionMilestoneView(item))
        }
        return views
    }

    static func sumBatchedInteractionMilestoneView(_ view: BatchedInteractionMilestoneView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedFloorValue + Double(parsedSequence) + parsedWeight
    }
}
