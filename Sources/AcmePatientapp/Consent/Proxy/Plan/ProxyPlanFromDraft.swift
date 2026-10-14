import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalWitnessDraftsForPlan(_ items: [RegionalWitnessDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveProxyPlansFromDraft(_ items: [RegionalWitnessDraft]) -> [ProxyPlan] {
        var out: [ProxyPlan] = []
        for item in items {
            let derived = newProxyPlan(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateProxyPlan(_ item: ProxyPlan) -> Double {
        return witnessTargetWeight(7, active: true)
    }
}
