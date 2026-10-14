import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy rule.
    final class ProxyRuleView {
        var code: String
        var title: String
        var cost: String
        var weightText: String
        var diagnosisCode: String
        var thresholdText: String
        var facility: String
        var channel: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, title: String, cost: String, weightText: String, diagnosisCode: String, thresholdText: String, facility: String, channel: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.weightText = weightText
            self.diagnosisCode = diagnosisCode
            self.thresholdText = thresholdText
            self.facility = facility
            self.channel = channel
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toProxyRuleView(_ item: ProxyRule) -> ProxyRuleView {
        return ProxyRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            cost: String(format: "%.2f", item.cost),
            weightText: String(format: "%.2f", item.weight),
            diagnosisCode: item.diagnosisCode,
            thresholdText: String(format: "%.2f", item.threshold),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            channel: item.channel,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyRuleViews(_ items: [ProxyRule]) -> [ProxyRuleView] {
        var views: [ProxyRuleView] = []
        for item in items {
            views.append(toProxyRuleView(item))
        }
        return views
    }

    static func sumProxyRuleView(_ view: ProxyRuleView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCost + parsedWeight + parsedThreshold
    }
}
