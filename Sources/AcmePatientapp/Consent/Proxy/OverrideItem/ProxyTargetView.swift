import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy target.
    final class ProxyTargetView {
        var code: String
        var name: String
        var cost: String
        var diagnosisCodeText: String
        var budgetText: String
        var endsAtText: String
        var weight: String
        var active: String
        var ceilingText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, name: String, cost: String, diagnosisCodeText: String, budgetText: String, endsAtText: String, weight: String, active: String, ceilingText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.diagnosisCodeText = diagnosisCodeText
            self.budgetText = budgetText
            self.endsAtText = endsAtText
            self.weight = weight
            self.active = active
            self.ceilingText = ceilingText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toProxyTargetView(_ item: ProxyTarget) -> ProxyTargetView {
        return ProxyTargetView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            diagnosisCodeText: item.diagnosisCode,
            budgetText: String(format: "%.2f", item.budget),
            endsAtText: String(item.endsAt),
            weight: String(format: "%.2f", item.weight),
            active: "\(item.active)",
            ceilingText: String(format: "%.2f", item.ceiling),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyTargetViews(_ items: [ProxyTarget]) -> [ProxyTargetView] {
        var views: [ProxyTargetView] = []
        for item in items {
            views.append(toProxyTargetView(item))
        }
        return views
    }

    static func sumProxyTargetView(_ view: ProxyTargetView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCost + parsedBudget + Double(parsedEndsAt)
    }
}
