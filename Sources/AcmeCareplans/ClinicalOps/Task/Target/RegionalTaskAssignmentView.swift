import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional task assignment.
    final class RegionalTaskAssignmentView {
        var code: String
        var title: String
        var pinned: String
        var channel: String
        var currencyText: String
        var ceiling: String
        var name: String
        var windowDays: String
        var costText: String
        var statusLabel: String

        init(code: String, title: String, pinned: String, channel: String, currencyText: String, ceiling: String, name: String, windowDays: String, costText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.channel = channel
            self.currencyText = currencyText
            self.ceiling = ceiling
            self.name = name
            self.windowDays = windowDays
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalTaskAssignmentView(_ item: RegionalTaskAssignment) -> RegionalTaskAssignmentView {
        return RegionalTaskAssignmentView(
            code: item.code,
            title: item.title,
            pinned: "\(item.pinned)",
            channel: item.channel,
            currencyText: item.currency,
            ceiling: String(format: "%.2f", item.ceiling),
            name: item.name,
            windowDays: String(item.windowDays),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalTaskAssignmentViews(_ items: [RegionalTaskAssignment]) -> [RegionalTaskAssignmentView] {
        var views: [RegionalTaskAssignmentView] = []
        for item in items {
            views.append(toRegionalTaskAssignmentView(item))
        }
        return views
    }

    static func sumRegionalTaskAssignmentView(_ view: RegionalTaskAssignmentView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCeiling + Double(parsedWindowDays) + parsedCost
    }
}
