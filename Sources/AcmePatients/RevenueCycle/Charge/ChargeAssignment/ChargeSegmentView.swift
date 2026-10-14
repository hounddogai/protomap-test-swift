import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge segment.
    final class ChargeSegmentView {
        var code: String
        var name: String
        var reviewer: String
        var windowDaysText: String
        var cost: String
        var limit: String
        var statusLabel: String

        init(code: String, name: String, reviewer: String, windowDaysText: String, cost: String, limit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.windowDaysText = windowDaysText
            self.cost = cost
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toChargeSegmentView(_ item: ChargeSegment) -> ChargeSegmentView {
        return ChargeSegmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            reviewer: item.reviewer,
            windowDaysText: String(item.windowDays),
            cost: String(format: "%.2f", item.cost),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeSegmentViews(_ items: [ChargeSegment]) -> [ChargeSegmentView] {
        var views: [ChargeSegmentView] = []
        for item in items {
            views.append(toChargeSegmentView(item))
        }
        return views
    }

    static func sumChargeSegmentView(_ view: ChargeSegmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedWindowDays) + parsedCost + Double(parsedLimit)
    }
}
