import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default float pool claim.
    final class DefaultFloatPoolClaimView {
        var code: String
        var labelText: String
        var limitText: String
        var unitText: String
        var channel: String
        var cost: String
        var locale: String
        var externalRef: String
        var statusLabel: String

        init(code: String, labelText: String, limitText: String, unitText: String, channel: String, cost: String, locale: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limitText = limitText
            self.unitText = unitText
            self.channel = channel
            self.cost = cost
            self.locale = locale
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultFloatPoolClaimView(_ item: DefaultFloatPoolClaim) -> DefaultFloatPoolClaimView {
        return DefaultFloatPoolClaimView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            limitText: String(item.limit),
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            channel: item.channel,
            cost: String(format: "%.2f", item.cost),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultFloatPoolClaimViews(_ items: [DefaultFloatPoolClaim]) -> [DefaultFloatPoolClaimView] {
        var views: [DefaultFloatPoolClaimView] = []
        for item in items {
            views.append(toDefaultFloatPoolClaimView(item))
        }
        return views
    }

    static func sumDefaultFloatPoolClaimView(_ view: DefaultFloatPoolClaimView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedLimit) + parsedCost
    }
}
