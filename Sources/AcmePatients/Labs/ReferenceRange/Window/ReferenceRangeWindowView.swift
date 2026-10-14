import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range window.
    final class ReferenceRangeWindowView {
        var code: String
        var title: String
        var priority: String
        var notes: String
        var procedureCode: String
        var durationMinutes: String
        var windowDays: String
        var capacity: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, priority: String, notes: String, procedureCode: String, durationMinutes: String, windowDays: String, capacity: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.priority = priority
            self.notes = notes
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.capacity = capacity
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeWindowView(_ item: ReferenceRangeWindow) -> ReferenceRangeWindowView {
        return ReferenceRangeWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            priority: String(item.priority),
            notes: item.notes,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            durationMinutes: String(item.durationMinutes),
            windowDays: String(item.windowDays),
            capacity: String(item.capacity),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeWindowViews(_ items: [ReferenceRangeWindow]) -> [ReferenceRangeWindowView] {
        var views: [ReferenceRangeWindowView] = []
        for item in items {
            views.append(toReferenceRangeWindowView(item))
        }
        return views
    }

    static func sumReferenceRangeWindowView(_ view: ReferenceRangeWindowView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedPriority) + Double(parsedDurationMinutes) + Double(parsedWindowDays)
    }
}
