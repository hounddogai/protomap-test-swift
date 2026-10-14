import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy mapping.
    final class ProxyMappingView {
        var codeText: String
        var title: String
        var copay: String
        var allergyText: String
        var weight: String
        var description: String
        var rate: String
        var summaryText: String
        var statusLabel: String

        init(codeText: String, title: String, copay: String, allergyText: String, weight: String, description: String, rate: String, summaryText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.copay = copay
            self.allergyText = allergyText
            self.weight = weight
            self.description = description
            self.rate = rate
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyMappingView(_ item: ProxyMapping) -> ProxyMappingView {
        return ProxyMappingView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            copay: String(format: "%.2f", item.copay),
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            weight: String(format: "%.2f", item.weight),
            description: Kit.Text.truncate(item.description, limit: 40),
            rate: String(format: "%.2f", item.rate),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyMappingViews(_ items: [ProxyMapping]) -> [ProxyMappingView] {
        var views: [ProxyMappingView] = []
        for item in items {
            views.append(toProxyMappingView(item))
        }
        return views
    }

    static func sumProxyMappingView(_ view: ProxyMappingView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCopay + parsedWeight + parsedRate
    }
}
