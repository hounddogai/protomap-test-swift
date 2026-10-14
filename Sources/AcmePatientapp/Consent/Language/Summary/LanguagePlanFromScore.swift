import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyScoresForPlan(_ items: [ProxyScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLanguagePlansFromScore(_ items: [ProxyScore]) -> [LanguagePlan] {
        var out: [LanguagePlan] = []
        for item in items {
            let derived = newLanguagePlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLanguagePlan(_ item: LanguagePlan) -> String {
        return classifyProxyRule(item.netVolume())
    }
}
