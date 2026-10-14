import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation baseline.
    final class IsolationBaselineView {
        var code: String
        var label: String
        var timezoneText: String
        var windowDaysText: String
        var facility: String
        var approvedText: String
        var floorValueText: String
        var rateText: String
        var channel: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, windowDaysText: String, facility: String, approvedText: String, floorValueText: String, rateText: String, channel: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.windowDaysText = windowDaysText
            self.facility = facility
            self.approvedText = approvedText
            self.floorValueText = floorValueText
            self.rateText = rateText
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationBaselineView(_ item: IsolationBaseline) -> IsolationBaselineView {
        return IsolationBaselineView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            timezoneText: item.timezone,
            windowDaysText: String(item.windowDays),
            facility: item.facility,
            approvedText: "\(item.approved)",
            floorValueText: String(format: "%.2f", item.floorValue),
            rateText: String(format: "%.2f", item.rate),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationBaselineViews(_ items: [IsolationBaseline]) -> [IsolationBaselineView] {
        var views: [IsolationBaselineView] = []
        for item in items {
            views.append(toIsolationBaselineView(item))
        }
        return views
    }

    static func sumIsolationBaselineView(_ view: IsolationBaselineView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedWindowDays) + parsedFloorValue + parsedRate
    }
}
