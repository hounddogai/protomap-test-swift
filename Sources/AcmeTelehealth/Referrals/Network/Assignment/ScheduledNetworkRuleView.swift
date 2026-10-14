import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled network rule.
    final class ScheduledNetworkRuleView {
        var code: String
        var title: String
        var endsAtText: String
        var costText: String
        var encounterID: String
        var ward: String
        var label: String
        var channelText: String
        var region: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, endsAtText: String, costText: String, encounterID: String, ward: String, label: String, channelText: String, region: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAtText = endsAtText
            self.costText = costText
            self.encounterID = encounterID
            self.ward = ward
            self.label = label
            self.channelText = channelText
            self.region = region
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledNetworkRuleView(_ item: ScheduledNetworkRule) -> ScheduledNetworkRuleView {
        return ScheduledNetworkRuleView(
            code: item.code,
            title: item.title,
            endsAtText: String(item.endsAt),
            costText: String(format: "%.2f", item.cost),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            ward: item.ward,
            label: item.label,
            channelText: item.channel,
            region: item.region,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledNetworkRuleViews(_ items: [ScheduledNetworkRule]) -> [ScheduledNetworkRuleView] {
        var views: [ScheduledNetworkRuleView] = []
        for item in items {
            views.append(toScheduledNetworkRuleView(item))
        }
        return views
    }

    static func sumScheduledNetworkRuleView(_ view: ScheduledNetworkRuleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedEndsAt) + parsedCost + Double(parsedRefills)
    }
}
