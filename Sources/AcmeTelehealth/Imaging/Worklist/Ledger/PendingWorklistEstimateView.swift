import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending worklist estimate.
    final class PendingWorklistEstimateView {
        var code: String
        var nameText: String
        var patientRef: String
        var visible: String
        var acuity: String
        var timezoneText: String
        var windowDays: String
        var cost: String
        var active: String
        var externalRefText: String
        var wardText: String
        var statusLabel: String

        init(code: String, nameText: String, patientRef: String, visible: String, acuity: String, timezoneText: String, windowDays: String, cost: String, active: String, externalRefText: String, wardText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.patientRef = patientRef
            self.visible = visible
            self.acuity = acuity
            self.timezoneText = timezoneText
            self.windowDays = windowDays
            self.cost = cost
            self.active = active
            self.externalRefText = externalRefText
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingWorklistEstimateView(_ item: PendingWorklistEstimate) -> PendingWorklistEstimateView {
        return PendingWorklistEstimateView(
            code: item.code,
            nameText: item.name,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            visible: "\(item.visible)",
            acuity: String(item.acuity),
            timezoneText: item.timezone,
            windowDays: String(item.windowDays),
            cost: String(format: "%.2f", item.cost),
            active: "\(item.active)",
            externalRefText: item.externalRef,
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingWorklistEstimateViews(_ items: [PendingWorklistEstimate]) -> [PendingWorklistEstimateView] {
        var views: [PendingWorklistEstimateView] = []
        for item in items {
            views.append(toPendingWorklistEstimateView(item))
        }
        return views
    }

    static func sumPendingWorklistEstimateView(_ view: PendingWorklistEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAcuity) + Double(parsedWindowDays) + parsedCost
    }
}
