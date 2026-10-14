import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling panel schedule.
    final class RollingPanelScheduleView {
        var code: String
        var label: String
        var ownerID: String
        var dosageMg: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, ownerID: String, dosageMg: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPanelScheduleView(_ item: RollingPanelSchedule) -> RollingPanelScheduleView {
        return RollingPanelScheduleView(
            code: item.code,
            label: item.label,
            ownerID: item.ownerID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPanelScheduleViews(_ items: [RollingPanelSchedule]) -> [RollingPanelScheduleView] {
        var views: [RollingPanelScheduleView] = []
        for item in items {
            views.append(toRollingPanelScheduleView(item))
        }
        return views
    }

    static func sumRollingPanelScheduleView(_ view: RollingPanelScheduleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedDosageMg + parsedThreshold
    }
}
