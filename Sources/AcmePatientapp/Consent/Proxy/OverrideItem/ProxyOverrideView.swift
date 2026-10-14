import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy override.
    final class ProxyOverrideView {
        var code: String
        var name: String
        var approved: String
        var expiresAt: String
        var channelText: String
        var statusLabel: String

        init(code: String, name: String, approved: String, expiresAt: String, channelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approved = approved
            self.expiresAt = expiresAt
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyOverrideView(_ item: ProxyOverride) -> ProxyOverrideView {
        return ProxyOverrideView(
            code: item.code,
            name: item.name,
            approved: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyOverrideViews(_ items: [ProxyOverride]) -> [ProxyOverrideView] {
        var views: [ProxyOverrideView] = []
        for item in items {
            views.append(toProxyOverrideView(item))
        }
        return views
    }

    static func sumProxyOverrideView(_ view: ProxyOverrideView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
