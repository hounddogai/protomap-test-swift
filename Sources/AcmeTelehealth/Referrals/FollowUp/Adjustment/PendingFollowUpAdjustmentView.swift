import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending follow up adjustment.
    final class PendingFollowUpAdjustmentView {
        var code: String
        var name: String
        var facilityText: String
        var floorValue: String
        var patientRef: String
        var timezoneText: String
        var graceDaysText: String
        var revision: String
        var reviewer: String
        var procedureCode: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, facilityText: String, floorValue: String, patientRef: String, timezoneText: String, graceDaysText: String, revision: String, reviewer: String, procedureCode: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facilityText = facilityText
            self.floorValue = floorValue
            self.patientRef = patientRef
            self.timezoneText = timezoneText
            self.graceDaysText = graceDaysText
            self.revision = revision
            self.reviewer = reviewer
            self.procedureCode = procedureCode
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFollowUpAdjustmentView(_ item: PendingFollowUpAdjustment) -> PendingFollowUpAdjustmentView {
        return PendingFollowUpAdjustmentView(
            code: item.code,
            name: item.name,
            facilityText: item.facility,
            floorValue: String(format: "%.2f", item.floorValue),
            patientRef: item.patientRef,
            timezoneText: item.timezone,
            graceDaysText: String(item.graceDays),
            revision: String(item.revision),
            reviewer: item.reviewer,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 120),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFollowUpAdjustmentViews(_ items: [PendingFollowUpAdjustment]) -> [PendingFollowUpAdjustmentView] {
        var views: [PendingFollowUpAdjustmentView] = []
        for item in items {
            views.append(toPendingFollowUpAdjustmentView(item))
        }
        return views
    }

    static func sumPendingFollowUpAdjustmentView(_ view: PendingFollowUpAdjustmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedFloorValue + Double(parsedGraceDays) + Double(parsedRevision)
    }
}
