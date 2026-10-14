import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a primary proxy policy.
    final class PrimaryProxyPolicyView {
        var code: String
        var titleText: String
        var windowDays: String
        var labelText: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, windowDays: String, labelText: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.windowDays = windowDays
            self.labelText = labelText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryProxyPolicyView(_ item: PrimaryProxyPolicy) -> PrimaryProxyPolicyView {
        return PrimaryProxyPolicyView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            windowDays: String(item.windowDays),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            country: Kit.Text.truncate(item.country, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryProxyPolicyViews(_ items: [PrimaryProxyPolicy]) -> [PrimaryProxyPolicyView] {
        var views: [PrimaryProxyPolicyView] = []
        for item in items {
            views.append(toPrimaryProxyPolicyView(item))
        }
        return views
    }

    static func sumPrimaryProxyPolicyView(_ view: PrimaryProxyPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
