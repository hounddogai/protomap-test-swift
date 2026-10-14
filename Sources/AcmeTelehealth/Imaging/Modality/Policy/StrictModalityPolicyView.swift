import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict modality policy.
    final class StrictModalityPolicyView {
        var code: String
        var label: String
        var ceiling: String
        var maximumText: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, maximumText: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.maximumText = maximumText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toStrictModalityPolicyView(_ item: StrictModalityPolicy) -> StrictModalityPolicyView {
        return StrictModalityPolicyView(
            code: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            maximumText: String(format: "%.2f", item.maximum),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictModalityPolicyViews(_ items: [StrictModalityPolicy]) -> [StrictModalityPolicyView] {
        var views: [StrictModalityPolicyView] = []
        for item in items {
            views.append(toStrictModalityPolicyView(item))
        }
        return views
    }

    static func sumStrictModalityPolicyView(_ view: StrictModalityPolicyView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCeiling + parsedMaximum + parsedCost
    }
}
