import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled isolation segment.
    final class ScheduledIsolationSegmentView {
        var code: String
        var nameText: String
        var notesText: String
        var updatedAt: String
        var limit: String
        var weightText: String
        var statusLabel: String

        init(code: String, nameText: String, notesText: String, updatedAt: String, limit: String, weightText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.notesText = notesText
            self.updatedAt = updatedAt
            self.limit = limit
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledIsolationSegmentView(_ item: ScheduledIsolationSegment) -> ScheduledIsolationSegmentView {
        return ScheduledIsolationSegmentView(
            code: item.code,
            nameText: item.name,
            notesText: item.notes,
            updatedAt: String(item.updatedAt),
            limit: String(item.limit),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledIsolationSegmentViews(_ items: [ScheduledIsolationSegment]) -> [ScheduledIsolationSegmentView] {
        var views: [ScheduledIsolationSegmentView] = []
        for item in items {
            views.append(toScheduledIsolationSegmentView(item))
        }
        return views
    }

    static func sumScheduledIsolationSegmentView(_ view: ScheduledIsolationSegmentView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedLimit) + parsedWeight
    }
}
