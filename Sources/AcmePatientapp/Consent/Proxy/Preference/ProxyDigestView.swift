import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy digest.
    final class ProxyDigestView {
        var code: String
        var titleText: String
        var margin: String
        var encounterIDText: String
        var payerText: String
        var name: String
        var summary: String
        var contactEmail: String
        var phone: String
        var statusLabel: String

        init(code: String, titleText: String, margin: String, encounterIDText: String, payerText: String, name: String, summary: String, contactEmail: String, phone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.margin = margin
            self.encounterIDText = encounterIDText
            self.payerText = payerText
            self.name = name
            self.summary = summary
            self.contactEmail = contactEmail
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toProxyDigestView(_ item: ProxyDigest) -> ProxyDigestView {
        return ProxyDigestView(
            code: item.code,
            titleText: item.title,
            margin: String(format: "%.2f", item.margin),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            payerText: Kit.Text.truncate(item.payer, limit: 120),
            name: item.name,
            summary: item.summary,
            contactEmail: item.contactEmail,
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyDigestViews(_ items: [ProxyDigest]) -> [ProxyDigestView] {
        var views: [ProxyDigestView] = []
        for item in items {
            views.append(toProxyDigestView(item))
        }
        return views
    }

    static func sumProxyDigestView(_ view: ProxyDigestView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
