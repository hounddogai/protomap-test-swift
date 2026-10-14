import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network plan.
    final class ManualNetworkPlanView {
        var codeText: String
        var nameText: String
        var discount: String
        var titleText: String
        var limitText: String
        var statusLabel: String

        init(codeText: String, nameText: String, discount: String, titleText: String, limitText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.discount = discount
            self.titleText = titleText
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkPlanView(_ item: ManualNetworkPlan) -> ManualNetworkPlanView {
        return ManualNetworkPlanView(
            codeText: item.code,
            nameText: item.name,
            discount: String(format: "%.2f", item.discount),
            titleText: item.title,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkPlanViews(_ items: [ManualNetworkPlan]) -> [ManualNetworkPlanView] {
        var views: [ManualNetworkPlanView] = []
        for item in items {
            views.append(toManualNetworkPlanView(item))
        }
        return views
    }

    static func sumManualNetworkPlanView(_ view: ManualNetworkPlanView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedDiscount + Double(parsedLimit)
    }
}
