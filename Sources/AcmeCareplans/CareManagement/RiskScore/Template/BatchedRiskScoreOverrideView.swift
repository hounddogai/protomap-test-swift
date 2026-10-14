import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched risk score override.
    final class BatchedRiskScoreOverrideView {
        var code: String
        var labelText: String
        var limit: String
        var priority: String
        var capacity: String
        var statusLabel: String

        init(code: String, labelText: String, limit: String, priority: String, capacity: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limit = limit
            self.priority = priority
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRiskScoreOverrideView(_ item: BatchedRiskScoreOverride) -> BatchedRiskScoreOverrideView {
        return BatchedRiskScoreOverrideView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            limit: String(item.limit),
            priority: String(item.priority),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRiskScoreOverrideViews(_ items: [BatchedRiskScoreOverride]) -> [BatchedRiskScoreOverrideView] {
        var views: [BatchedRiskScoreOverrideView] = []
        for item in items {
            views.append(toBatchedRiskScoreOverrideView(item))
        }
        return views
    }

    static func sumBatchedRiskScoreOverrideView(_ view: BatchedRiskScoreOverrideView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority) + Double(parsedCapacity)
    }
}
