import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled panel score.
    final class ScheduledPanelScoreView {
        var code: String
        var nameText: String
        var maximum: String
        var capacity: String
        var externalRef: String
        var visitMinutesText: String
        var ward: String
        var currencyText: String
        var regionText: String
        var costText: String
        var statusLabel: String

        init(code: String, nameText: String, maximum: String, capacity: String, externalRef: String, visitMinutesText: String, ward: String, currencyText: String, regionText: String, costText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximum = maximum
            self.capacity = capacity
            self.externalRef = externalRef
            self.visitMinutesText = visitMinutesText
            self.ward = ward
            self.currencyText = currencyText
            self.regionText = regionText
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPanelScoreView(_ item: ScheduledPanelScore) -> ScheduledPanelScoreView {
        return ScheduledPanelScoreView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: Kit.Text.truncate(item.name, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            capacity: String(item.capacity),
            externalRef: item.externalRef,
            visitMinutesText: String(item.visitMinutes),
            ward: item.ward,
            currencyText: item.currency,
            regionText: item.region,
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPanelScoreViews(_ items: [ScheduledPanelScore]) -> [ScheduledPanelScoreView] {
        var views: [ScheduledPanelScoreView] = []
        for item in items {
            views.append(toScheduledPanelScoreView(item))
        }
        return views
    }

    static func sumScheduledPanelScoreView(_ view: ScheduledPanelScoreView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMaximum + Double(parsedCapacity) + Double(parsedVisitMinutes)
    }
}
