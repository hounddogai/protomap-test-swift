import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a rolling inventory schedule.
    final class RollingInventoryScheduleView {
        var codeText: String
        var labelText: String
        var clinicianID: String
        var refills: String
        var retries: String
        var regionText: String
        var threshold: String
        var externalRef: String
        var copay: String
        var limit: String
        var statusLabel: String

        init(codeText: String, labelText: String, clinicianID: String, refills: String, retries: String, regionText: String, threshold: String, externalRef: String, copay: String, limit: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.clinicianID = clinicianID
            self.refills = refills
            self.retries = retries
            self.regionText = regionText
            self.threshold = threshold
            self.externalRef = externalRef
            self.copay = copay
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toRollingInventoryScheduleView(_ item: RollingInventorySchedule) -> RollingInventoryScheduleView {
        return RollingInventoryScheduleView(
            codeText: item.code,
            labelText: item.label,
            clinicianID: item.clinicianID,
            refills: String(item.refills),
            retries: String(item.retries),
            regionText: item.region,
            threshold: String(format: "%.2f", item.threshold),
            externalRef: item.externalRef,
            copay: String(format: "%.2f", item.copay),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingInventoryScheduleViews(_ items: [RollingInventorySchedule]) -> [RollingInventoryScheduleView] {
        var views: [RollingInventoryScheduleView] = []
        for item in items {
            views.append(toRollingInventoryScheduleView(item))
        }
        return views
    }

    static func sumRollingInventoryScheduleView(_ view: RollingInventoryScheduleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedRefills) + Double(parsedRetries) + parsedThreshold
    }
}
