import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan group.
    final class AcuityPlanGroupView {
        var codeText: String
        var label: String
        var startsAt: String
        var durationMinutes: String
        var windowDaysText: String
        var statusLabel: String

        init(codeText: String, label: String, startsAt: String, durationMinutes: String, windowDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.startsAt = startsAt
            self.durationMinutes = durationMinutes
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanGroupView(_ item: AcuityPlanGroup) -> AcuityPlanGroupView {
        return AcuityPlanGroupView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            startsAt: String(item.startsAt),
            durationMinutes: String(item.durationMinutes),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanGroupViews(_ items: [AcuityPlanGroup]) -> [AcuityPlanGroupView] {
        var views: [AcuityPlanGroupView] = []
        for item in items {
            views.append(toAcuityPlanGroupView(item))
        }
        return views
    }

    static func sumAcuityPlanGroupView(_ view: AcuityPlanGroupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedDurationMinutes) + Double(parsedWindowDays)
    }
}
