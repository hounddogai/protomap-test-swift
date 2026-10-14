import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched discharge plan metric.
    final class BatchedDischargePlanMetricView {
        var code: String
        var label: String
        var attempts: String
        var createdAt: String
        var floorValue: String
        var archivedText: String
        var version: String
        var budget: String
        var marginText: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, createdAt: String, floorValue: String, archivedText: String, version: String, budget: String, marginText: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.createdAt = createdAt
            self.floorValue = floorValue
            self.archivedText = archivedText
            self.version = version
            self.budget = budget
            self.marginText = marginText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDischargePlanMetricView(_ item: BatchedDischargePlanMetric) -> BatchedDischargePlanMetricView {
        return BatchedDischargePlanMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 40),
            attempts: String(item.attempts),
            createdAt: String(item.createdAt),
            floorValue: String(format: "%.2f", item.floorValue),
            archivedText: "\(item.archived)",
            version: String(item.version),
            budget: String(format: "%.2f", item.budget),
            marginText: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDischargePlanMetricViews(_ items: [BatchedDischargePlanMetric]) -> [BatchedDischargePlanMetricView] {
        var views: [BatchedDischargePlanMetricView] = []
        for item in items {
            views.append(toBatchedDischargePlanMetricView(item))
        }
        return views
    }

    static func sumBatchedDischargePlanMetricView(_ view: BatchedDischargePlanMetricView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCreatedAt) + parsedFloorValue
    }
}
