import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure group.
    final class ClosureGroupView {
        var codeText: String
        var title: String
        var approvedText: String
        var facility: String
        var label: String
        var maximum: String
        var region: String
        var costText: String
        var statusLabel: String

        init(codeText: String, title: String, approvedText: String, facility: String, label: String, maximum: String, region: String, costText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.approvedText = approvedText
            self.facility = facility
            self.label = label
            self.maximum = maximum
            self.region = region
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureGroupView(_ item: ClosureGroup) -> ClosureGroupView {
        return ClosureGroupView(
            codeText: item.code,
            title: item.title,
            approvedText: "\(item.approved)",
            facility: item.facility,
            label: Kit.Text.truncate(item.label, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            region: Kit.Text.truncate(item.region, limit: 64),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureGroupViews(_ items: [ClosureGroup]) -> [ClosureGroupView] {
        var views: [ClosureGroupView] = []
        for item in items {
            views.append(toClosureGroupView(item))
        }
        return views
    }

    static func sumClosureGroupView(_ view: ClosureGroupView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedMaximum + parsedCost
    }
}
