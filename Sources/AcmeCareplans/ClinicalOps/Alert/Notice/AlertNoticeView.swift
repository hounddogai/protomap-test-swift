import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert notice.
    final class AlertNoticeView {
        var code: String
        var nameText: String
        var refillsText: String
        var weight: String
        var windowDays: String
        var regionText: String
        var channel: String
        var graceDays: String
        var sequenceText: String
        var costText: String
        var statusLabel: String

        init(code: String, nameText: String, refillsText: String, weight: String, windowDays: String, regionText: String, channel: String, graceDays: String, sequenceText: String, costText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.refillsText = refillsText
            self.weight = weight
            self.windowDays = windowDays
            self.regionText = regionText
            self.channel = channel
            self.graceDays = graceDays
            self.sequenceText = sequenceText
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertNoticeView(_ item: AlertNotice) -> AlertNoticeView {
        return AlertNoticeView(
            code: item.code,
            nameText: item.name,
            refillsText: String(item.refills),
            weight: String(format: "%.2f", item.weight),
            windowDays: String(item.windowDays),
            regionText: item.region,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            graceDays: String(item.graceDays),
            sequenceText: String(item.sequence),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertNoticeViews(_ items: [AlertNotice]) -> [AlertNoticeView] {
        var views: [AlertNoticeView] = []
        for item in items {
            views.append(toAlertNoticeView(item))
        }
        return views
    }

    static func sumAlertNoticeView(_ view: AlertNoticeView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedRefills) + parsedWeight + Double(parsedWindowDays)
    }
}
