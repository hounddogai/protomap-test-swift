import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result target.
    final class ResultTargetView {
        var code: String
        var name: String
        var visibleText: String
        var summary: String
        var facility: String
        var notes: String
        var durationMinutes: String
        var unitText: String
        var minimumText: String
        var windowDays: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, summary: String, facility: String, notes: String, durationMinutes: String, unitText: String, minimumText: String, windowDays: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.summary = summary
            self.facility = facility
            self.notes = notes
            self.durationMinutes = durationMinutes
            self.unitText = unitText
            self.minimumText = minimumText
            self.windowDays = windowDays
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toResultTargetView(_ item: ResultTarget) -> ResultTargetView {
        return ResultTargetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            visibleText: "\(item.visible)",
            summary: item.summary,
            facility: Kit.Text.truncate(item.facility, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            durationMinutes: String(item.durationMinutes),
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            minimumText: String(format: "%.2f", item.minimum),
            windowDays: String(item.windowDays),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultTargetViews(_ items: [ResultTarget]) -> [ResultTargetView] {
        var views: [ResultTargetView] = []
        for item in items {
            views.append(toResultTargetView(item))
        }
        return views
    }

    static func sumResultTargetView(_ view: ResultTargetView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMinimum + Double(parsedWindowDays)
    }
}
