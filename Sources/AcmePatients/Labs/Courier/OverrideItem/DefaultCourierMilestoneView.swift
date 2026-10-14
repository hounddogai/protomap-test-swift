import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default courier milestone.
    final class DefaultCourierMilestoneView {
        var code: String
        var title: String
        var durationMinutes: String
        var weight: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, durationMinutes: String, weight: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCourierMilestoneView(_ item: DefaultCourierMilestone) -> DefaultCourierMilestoneView {
        return DefaultCourierMilestoneView(
            code: item.code,
            title: item.title,
            durationMinutes: String(item.durationMinutes),
            weight: String(format: "%.2f", item.weight),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCourierMilestoneViews(_ items: [DefaultCourierMilestone]) -> [DefaultCourierMilestoneView] {
        var views: [DefaultCourierMilestoneView] = []
        for item in items {
            views.append(toDefaultCourierMilestoneView(item))
        }
        return views
    }

    static func sumDefaultCourierMilestoneView(_ view: DefaultCourierMilestoneView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedDurationMinutes) + parsedWeight + parsedFloorValue
    }
}
