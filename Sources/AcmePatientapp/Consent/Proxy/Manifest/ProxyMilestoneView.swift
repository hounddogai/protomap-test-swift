import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy milestone.
    final class ProxyMilestoneView {
        var code: String
        var name: String
        var currencyText: String
        var facility: String
        var retries: String
        var payer: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, name: String, currencyText: String, facility: String, retries: String, payer: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.currencyText = currencyText
            self.facility = facility
            self.retries = retries
            self.payer = payer
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyMilestoneView(_ item: ProxyMilestone) -> ProxyMilestoneView {
        return ProxyMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            retries: String(item.retries),
            payer: item.payer,
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyMilestoneViews(_ items: [ProxyMilestone]) -> [ProxyMilestoneView] {
        var views: [ProxyMilestoneView] = []
        for item in items {
            views.append(toProxyMilestoneView(item))
        }
        return views
    }

    static func sumProxyMilestoneView(_ view: ProxyMilestoneView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
