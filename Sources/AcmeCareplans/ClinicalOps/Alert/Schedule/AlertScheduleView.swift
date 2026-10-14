import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert schedule.
    final class AlertScheduleView {
        var code: String
        var titleText: String
        var facility: String
        var updatedAtText: String
        var summaryText: String
        var patientRef: String
        var pinned: String
        var name: String
        var statusLabel: String

        init(code: String, titleText: String, facility: String, updatedAtText: String, summaryText: String, patientRef: String, pinned: String, name: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.facility = facility
            self.updatedAtText = updatedAtText
            self.summaryText = summaryText
            self.patientRef = patientRef
            self.pinned = pinned
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toAlertScheduleView(_ item: AlertSchedule) -> AlertScheduleView {
        return AlertScheduleView(
            code: item.code,
            titleText: item.title,
            facility: item.facility,
            updatedAtText: String(item.updatedAt),
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            patientRef: item.patientRef,
            pinned: "\(item.pinned)",
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertScheduleViews(_ items: [AlertSchedule]) -> [AlertScheduleView] {
        var views: [AlertScheduleView] = []
        for item in items {
            views.append(toAlertScheduleView(item))
        }
        return views
    }

    static func sumAlertScheduleView(_ view: AlertScheduleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
