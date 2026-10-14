import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan schedule.
    final class AcuityPlanScheduleView {
        var codeText: String
        var label: String
        var marginText: String
        var ceiling: String
        var externalRefText: String
        var statusLabel: String

        init(codeText: String, label: String, marginText: String, ceiling: String, externalRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.marginText = marginText
            self.ceiling = ceiling
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanScheduleView(_ item: AcuityPlanSchedule) -> AcuityPlanScheduleView {
        return AcuityPlanScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            marginText: String(format: "%.2f", item.margin),
            ceiling: String(format: "%.2f", item.ceiling),
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanScheduleViews(_ items: [AcuityPlanSchedule]) -> [AcuityPlanScheduleView] {
        var views: [AcuityPlanScheduleView] = []
        for item in items {
            views.append(toAcuityPlanScheduleView(item))
        }
        return views
    }

    static func sumAcuityPlanScheduleView(_ view: AcuityPlanScheduleView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMargin + parsedCeiling
    }
}
