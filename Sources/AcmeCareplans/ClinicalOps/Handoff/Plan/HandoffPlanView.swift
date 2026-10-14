import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff plan.
    final class HandoffPlanView {
        var code: String
        var nameText: String
        var ownerID: String
        var batchSize: String
        var segment: String
        var minimumText: String
        var facility: String
        var durationMinutes: String
        var capacity: String
        var channel: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, nameText: String, ownerID: String, batchSize: String, segment: String, minimumText: String, facility: String, durationMinutes: String, capacity: String, channel: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ownerID = ownerID
            self.batchSize = batchSize
            self.segment = segment
            self.minimumText = minimumText
            self.facility = facility
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.channel = channel
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffPlanView(_ item: HandoffPlan) -> HandoffPlanView {
        return HandoffPlanView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            ownerID: item.ownerID,
            batchSize: String(item.batchSize),
            segment: item.segment,
            minimumText: String(format: "%.2f", item.minimum),
            facility: item.facility,
            durationMinutes: String(item.durationMinutes),
            capacity: String(item.capacity),
            channel: item.channel,
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffPlanViews(_ items: [HandoffPlan]) -> [HandoffPlanView] {
        var views: [HandoffPlanView] = []
        for item in items {
            views.append(toHandoffPlanView(item))
        }
        return views
    }

    static func sumHandoffPlanView(_ view: HandoffPlanView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedBatchSize) + parsedMinimum + Double(parsedDurationMinutes)
    }
}
