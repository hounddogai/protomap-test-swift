import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy window.
    final class ProxyWindowView {
        var code: String
        var label: String
        var facility: String
        var rate: String
        var limit: String
        var endsAt: String
        var refills: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, facility: String, rate: String, limit: String, endsAt: String, refills: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.facility = facility
            self.rate = rate
            self.limit = limit
            self.endsAt = endsAt
            self.refills = refills
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toProxyWindowView(_ item: ProxyWindow) -> ProxyWindowView {
        return ProxyWindowView(
            code: item.code,
            label: item.label,
            facility: item.facility,
            rate: String(format: "%.2f", item.rate),
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            refills: String(item.refills),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyWindowViews(_ items: [ProxyWindow]) -> [ProxyWindowView] {
        var views: [ProxyWindowView] = []
        for item in items {
            views.append(toProxyWindowView(item))
        }
        return views
    }

    static func sumProxyWindowView(_ view: ProxyWindowView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedRate + Double(parsedLimit) + Double(parsedEndsAt)
    }
}
