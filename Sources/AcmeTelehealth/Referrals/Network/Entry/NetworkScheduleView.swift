import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network schedule.
    final class NetworkScheduleView {
        var code: String
        var title: String
        var margin: String
        var acuity: String
        var windowDays: String
        var currencyText: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, margin: String, acuity: String, windowDays: String, currencyText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.margin = margin
            self.acuity = acuity
            self.windowDays = windowDays
            self.currencyText = currencyText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkScheduleView(_ item: NetworkSchedule) -> NetworkScheduleView {
        return NetworkScheduleView(
            code: item.code,
            title: item.title,
            margin: String(format: "%.2f", item.margin),
            acuity: String(item.acuity),
            windowDays: String(item.windowDays),
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkScheduleViews(_ items: [NetworkSchedule]) -> [NetworkScheduleView] {
        var views: [NetworkScheduleView] = []
        for item in items {
            views.append(toNetworkScheduleView(item))
        }
        return views
    }

    static func sumNetworkScheduleView(_ view: NetworkScheduleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedMargin + Double(parsedAcuity) + Double(parsedWindowDays)
    }
}
