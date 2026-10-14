import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling discharge plan schedule.
    final class RollingDischargePlanScheduleView {
        var code: String
        var label: String
        var categoryText: String
        var ceiling: String
        var segmentText: String
        var unitText: String
        var channel: String
        var maximum: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, categoryText: String, ceiling: String, segmentText: String, unitText: String, channel: String, maximum: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.categoryText = categoryText
            self.ceiling = ceiling
            self.segmentText = segmentText
            self.unitText = unitText
            self.channel = channel
            self.maximum = maximum
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDischargePlanScheduleView(_ item: RollingDischargePlanSchedule) -> RollingDischargePlanScheduleView {
        return RollingDischargePlanScheduleView(
            code: item.code,
            label: item.label,
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            ceiling: String(format: "%.2f", item.ceiling),
            segmentText: item.segment,
            unitText: item.unit,
            channel: Kit.Text.truncate(item.channel, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDischargePlanScheduleViews(_ items: [RollingDischargePlanSchedule]) -> [RollingDischargePlanScheduleView] {
        var views: [RollingDischargePlanScheduleView] = []
        for item in items {
            views.append(toRollingDischargePlanScheduleView(item))
        }
        return views
    }

    static func sumRollingDischargePlanScheduleView(_ view: RollingDischargePlanScheduleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedMaximum
    }
}
