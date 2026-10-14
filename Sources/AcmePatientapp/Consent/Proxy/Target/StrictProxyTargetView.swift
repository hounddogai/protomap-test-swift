import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict proxy target.
    final class StrictProxyTargetView {
        var codeText: String
        var label: String
        var budget: String
        var limit: String
        var floorValueText: String
        var statusLabel: String

        init(codeText: String, label: String, budget: String, limit: String, floorValueText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.budget = budget
            self.limit = limit
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictProxyTargetView(_ item: StrictProxyTarget) -> StrictProxyTargetView {
        return StrictProxyTargetView(
            codeText: item.code,
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            limit: String(item.limit),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictProxyTargetViews(_ items: [StrictProxyTarget]) -> [StrictProxyTargetView] {
        var views: [StrictProxyTargetView] = []
        for item in items {
            views.append(toStrictProxyTargetView(item))
        }
        return views
    }

    static func sumStrictProxyTargetView(_ view: StrictProxyTargetView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedBudget + Double(parsedLimit) + parsedFloorValue
    }
}
