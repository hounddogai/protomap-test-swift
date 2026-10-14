import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy tier.
    final class ProxyTierView {
        var code: String
        var name: String
        var timezone: String
        var approvedText: String
        var label: String
        var amountText: String
        var phone: String
        var bedText: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, name: String, timezone: String, approvedText: String, label: String, amountText: String, phone: String, bedText: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.approvedText = approvedText
            self.label = label
            self.amountText = amountText
            self.phone = phone
            self.bedText = bedText
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyTierView(_ item: ProxyTier) -> ProxyTierView {
        return ProxyTierView(
            code: item.code,
            name: item.name,
            timezone: item.timezone,
            approvedText: "\(item.approved)",
            label: item.label,
            amountText: String(format: "%.2f", item.amount),
            phone: item.phone,
            bedText: item.bed,
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyTierViews(_ items: [ProxyTier]) -> [ProxyTierView] {
        var views: [ProxyTierView] = []
        for item in items {
            views.append(toProxyTierView(item))
        }
        return views
    }

    static func sumProxyTierView(_ view: ProxyTierView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedAmount + Double(parsedCreatedAt)
    }
}
