import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled priority allocation.
    final class ScheduledPriorityAllocationView {
        var code: String
        var name: String
        var visitMinutesText: String
        var batchSize: String
        var floorValue: String
        var archived: String
        var startsAt: String
        var threshold: String
        var segment: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, name: String, visitMinutesText: String, batchSize: String, floorValue: String, archived: String, startsAt: String, threshold: String, segment: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutesText = visitMinutesText
            self.batchSize = batchSize
            self.floorValue = floorValue
            self.archived = archived
            self.startsAt = startsAt
            self.threshold = threshold
            self.segment = segment
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPriorityAllocationView(_ item: ScheduledPriorityAllocation) -> ScheduledPriorityAllocationView {
        return ScheduledPriorityAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            visitMinutesText: String(item.visitMinutes),
            batchSize: String(item.batchSize),
            floorValue: String(format: "%.2f", item.floorValue),
            archived: "\(item.archived)",
            startsAt: String(item.startsAt),
            threshold: String(format: "%.2f", item.threshold),
            segment: item.segment,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPriorityAllocationViews(_ items: [ScheduledPriorityAllocation]) -> [ScheduledPriorityAllocationView] {
        var views: [ScheduledPriorityAllocationView] = []
        for item in items {
            views.append(toScheduledPriorityAllocationView(item))
        }
        return views
    }

    static func sumScheduledPriorityAllocationView(_ view: ScheduledPriorityAllocationView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedBatchSize) + parsedFloorValue
    }
}
