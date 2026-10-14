import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a scheduled proxy group.
    final class ScheduledProxyGroupView {
        var code: String
        var label: String
        var capacity: String
        var updatedAt: String
        var patientRef: String
        var batchSize: String
        var clinicianID: String
        var ceiling: String
        var sequence: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, updatedAt: String, patientRef: String, batchSize: String, clinicianID: String, ceiling: String, sequence: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.clinicianID = clinicianID
            self.ceiling = ceiling
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledProxyGroupView(_ item: ScheduledProxyGroup) -> ScheduledProxyGroupView {
        return ScheduledProxyGroupView(
            code: item.code,
            label: item.label,
            capacity: String(item.capacity),
            updatedAt: String(item.updatedAt),
            patientRef: item.patientRef,
            batchSize: String(item.batchSize),
            clinicianID: item.clinicianID,
            ceiling: String(format: "%.2f", item.ceiling),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledProxyGroupViews(_ items: [ScheduledProxyGroup]) -> [ScheduledProxyGroupView] {
        var views: [ScheduledProxyGroupView] = []
        for item in items {
            views.append(toScheduledProxyGroupView(item))
        }
        return views
    }

    static func sumScheduledProxyGroupView(_ view: ScheduledProxyGroupView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedCapacity) + Double(parsedUpdatedAt) + Double(parsedBatchSize)
    }
}
