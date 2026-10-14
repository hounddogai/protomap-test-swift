import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy score.
    final class ProxyScoreView {
        var code: String
        var title: String
        var margin: String
        var facilityText: String
        var ratio: String
        var weight: String
        var budget: String
        var statusLabel: String

        init(code: String, title: String, margin: String, facilityText: String, ratio: String, weight: String, budget: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.margin = margin
            self.facilityText = facilityText
            self.ratio = ratio
            self.weight = weight
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toProxyScoreView(_ item: ProxyScore) -> ProxyScoreView {
        return ProxyScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            margin: String(format: "%.2f", item.margin),
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            weight: String(format: "%.2f", item.weight),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyScoreViews(_ items: [ProxyScore]) -> [ProxyScoreView] {
        var views: [ProxyScoreView] = []
        for item in items {
            views.append(toProxyScoreView(item))
        }
        return views
    }

    static func sumProxyScoreView(_ view: ProxyScoreView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMargin + parsedRatio + parsedWeight
    }
}
