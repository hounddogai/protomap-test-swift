import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime schedule.
    final class OvertimeScheduleView {
        var code: String
        var title: String
        var durationMinutes: String
        var floorValueText: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, floorValueText: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.floorValueText = floorValueText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeScheduleView(_ item: OvertimeSchedule) -> OvertimeScheduleView {
        return OvertimeScheduleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            durationMinutes: String(item.durationMinutes),
            floorValueText: String(format: "%.2f", item.floorValue),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeScheduleViews(_ items: [OvertimeSchedule]) -> [OvertimeScheduleView] {
        var views: [OvertimeScheduleView] = []
        for item in items {
            views.append(toOvertimeScheduleView(item))
        }
        return views
    }

    static func sumOvertimeScheduleView(_ view: OvertimeScheduleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedDurationMinutes) + parsedFloorValue + parsedMargin
    }
}
