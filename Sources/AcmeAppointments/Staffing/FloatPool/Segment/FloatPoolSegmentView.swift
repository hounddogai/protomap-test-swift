import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool segment.
    final class FloatPoolSegmentView {
        var code: String
        var titleText: String
        var encounterIDText: String
        var updatedAtText: String
        var expiresAt: String
        var priorityText: String
        var endsAt: String
        var active: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, encounterIDText: String, updatedAtText: String, expiresAt: String, priorityText: String, endsAt: String, active: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.encounterIDText = encounterIDText
            self.updatedAtText = updatedAtText
            self.expiresAt = expiresAt
            self.priorityText = priorityText
            self.endsAt = endsAt
            self.active = active
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolSegmentView(_ item: FloatPoolSegment) -> FloatPoolSegmentView {
        return FloatPoolSegmentView(
            code: item.code,
            titleText: item.title,
            encounterIDText: item.encounterID,
            updatedAtText: String(item.updatedAt),
            expiresAt: String(item.expiresAt),
            priorityText: String(item.priority),
            endsAt: String(item.endsAt),
            active: "\(item.active)",
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolSegmentViews(_ items: [FloatPoolSegment]) -> [FloatPoolSegmentView] {
        var views: [FloatPoolSegmentView] = []
        for item in items {
            views.append(toFloatPoolSegmentView(item))
        }
        return views
    }

    static func sumFloatPoolSegmentView(_ view: FloatPoolSegmentView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedExpiresAt) + Double(parsedPriority)
    }
}
