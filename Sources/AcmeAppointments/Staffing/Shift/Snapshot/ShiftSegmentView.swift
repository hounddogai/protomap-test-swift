import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift segment.
    final class ShiftSegmentView {
        var code: String
        var labelText: String
        var windowDaysText: String
        var locale: String
        var budget: String
        var priority: String
        var dosageMgText: String
        var segment: String
        var pinned: String
        var description: String
        var statusLabel: String

        init(code: String, labelText: String, windowDaysText: String, locale: String, budget: String, priority: String, dosageMgText: String, segment: String, pinned: String, description: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDaysText = windowDaysText
            self.locale = locale
            self.budget = budget
            self.priority = priority
            self.dosageMgText = dosageMgText
            self.segment = segment
            self.pinned = pinned
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toShiftSegmentView(_ item: ShiftSegment) -> ShiftSegmentView {
        return ShiftSegmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            windowDaysText: String(item.windowDays),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            budget: String(format: "%.2f", item.budget),
            priority: String(item.priority),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            pinned: "\(item.pinned)",
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftSegmentViews(_ items: [ShiftSegment]) -> [ShiftSegmentView] {
        var views: [ShiftSegmentView] = []
        for item in items {
            views.append(toShiftSegmentView(item))
        }
        return views
    }

    static func sumShiftSegmentView(_ view: ShiftSegmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + Double(parsedPriority)
    }
}
