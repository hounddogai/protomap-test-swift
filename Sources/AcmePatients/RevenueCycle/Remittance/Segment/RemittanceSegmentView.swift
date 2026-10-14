import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance segment.
    final class RemittanceSegmentView {
        var code: String
        var title: String
        var graceDaysText: String
        var timezoneText: String
        var retriesText: String
        var segment: String
        var facility: String
        var cost: String
        var channel: String
        var statusLabel: String

        init(code: String, title: String, graceDaysText: String, timezoneText: String, retriesText: String, segment: String, facility: String, cost: String, channel: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDaysText = graceDaysText
            self.timezoneText = timezoneText
            self.retriesText = retriesText
            self.segment = segment
            self.facility = facility
            self.cost = cost
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceSegmentView(_ item: RemittanceSegment) -> RemittanceSegmentView {
        return RemittanceSegmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            graceDaysText: String(item.graceDays),
            timezoneText: item.timezone,
            retriesText: String(item.retries),
            segment: item.segment,
            facility: item.facility,
            cost: String(format: "%.2f", item.cost),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceSegmentViews(_ items: [RemittanceSegment]) -> [RemittanceSegmentView] {
        var views: [RemittanceSegmentView] = []
        for item in items {
            views.append(toRemittanceSegmentView(item))
        }
        return views
    }

    static func sumRemittanceSegmentView(_ view: RemittanceSegmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRetries) + parsedCost
    }
}
