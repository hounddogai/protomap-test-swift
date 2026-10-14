import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending worklist metric.
    final class PendingWorklistMetricView {
        var code: String
        var labelText: String
        var endsAtText: String
        var batchSize: String
        var cost: String
        var durationMinutesText: String
        var limit: String
        var capacityText: String
        var allergy: String
        var createdAtText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, endsAtText: String, batchSize: String, cost: String, durationMinutesText: String, limit: String, capacityText: String, allergy: String, createdAtText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.endsAtText = endsAtText
            self.batchSize = batchSize
            self.cost = cost
            self.durationMinutesText = durationMinutesText
            self.limit = limit
            self.capacityText = capacityText
            self.allergy = allergy
            self.createdAtText = createdAtText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toPendingWorklistMetricView(_ item: PendingWorklistMetric) -> PendingWorklistMetricView {
        return PendingWorklistMetricView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            endsAtText: String(item.endsAt),
            batchSize: String(item.batchSize),
            cost: String(format: "%.2f", item.cost),
            durationMinutesText: String(item.durationMinutes),
            limit: String(item.limit),
            capacityText: String(item.capacity),
            allergy: item.allergy,
            createdAtText: String(item.createdAt),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingWorklistMetricViews(_ items: [PendingWorklistMetric]) -> [PendingWorklistMetricView] {
        var views: [PendingWorklistMetricView] = []
        for item in items {
            views.append(toPendingWorklistMetricView(item))
        }
        return views
    }

    static func sumPendingWorklistMetricView(_ view: PendingWorklistMetricView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedBatchSize) + parsedCost
    }
}
