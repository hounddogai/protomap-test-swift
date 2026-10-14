import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift schedule.
    final class ShiftScheduleView {
        var code: String
        var label: String
        var patientRef: String
        var refills: String
        var reviewer: String
        var threshold: String
        var version: String
        var region: String
        var copayText: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, refills: String, reviewer: String, threshold: String, version: String, region: String, copayText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.refills = refills
            self.reviewer = reviewer
            self.threshold = threshold
            self.version = version
            self.region = region
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toShiftScheduleView(_ item: ShiftSchedule) -> ShiftScheduleView {
        return ShiftScheduleView(
            code: item.code,
            label: item.label,
            patientRef: item.patientRef,
            refills: String(item.refills),
            reviewer: item.reviewer,
            threshold: String(format: "%.2f", item.threshold),
            version: String(item.version),
            region: item.region,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftScheduleViews(_ items: [ShiftSchedule]) -> [ShiftScheduleView] {
        var views: [ShiftScheduleView] = []
        for item in items {
            views.append(toShiftScheduleView(item))
        }
        return views
    }

    static func sumShiftScheduleView(_ view: ShiftScheduleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedRefills) + parsedThreshold + Double(parsedVersion)
    }
}
