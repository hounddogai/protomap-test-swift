import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot policy.
    final class SlotPolicyView {
        var code: String
        var title: String
        var discountText: String
        var region: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, title: String, discountText: String, region: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discountText = discountText
            self.region = region
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotPolicyView(_ item: SlotPolicy) -> SlotPolicyView {
        return SlotPolicyView(
            code: item.code,
            title: item.title,
            discountText: String(format: "%.2f", item.discount),
            region: Kit.Text.truncate(item.region, limit: 120),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotPolicyViews(_ items: [SlotPolicy]) -> [SlotPolicyView] {
        var views: [SlotPolicyView] = []
        for item in items {
            views.append(toSlotPolicyView(item))
        }
        return views
    }

    static func sumSlotPolicyView(_ view: SlotPolicyView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedDiscount + parsedCeiling
    }
}
