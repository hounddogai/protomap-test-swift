import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier window.
    final class CourierWindowView {
        var code: String
        var title: String
        var revision: String
        var durationMinutes: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, revision: String, durationMinutes: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.revision = revision
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toCourierWindowView(_ item: CourierWindow) -> CourierWindowView {
        return CourierWindowView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            revision: String(item.revision),
            durationMinutes: String(item.durationMinutes),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierWindowViews(_ items: [CourierWindow]) -> [CourierWindowView] {
        var views: [CourierWindowView] = []
        for item in items {
            views.append(toCourierWindowView(item))
        }
        return views
    }

    static func sumCourierWindowView(_ view: CourierWindowView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRevision) + Double(parsedDurationMinutes) + parsedFloorValue
    }
}
