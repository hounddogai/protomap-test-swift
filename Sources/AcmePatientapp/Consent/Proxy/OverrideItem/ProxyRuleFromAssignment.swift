import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictWitnessAssignmentsForRule(_ items: [StrictWitnessAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveProxyRulesFromAssignment(_ items: [StrictWitnessAssignment]) -> [ProxyRule] {
        var out: [ProxyRule] = []
        for item in items {
            let derived = newProxyRule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyProxyRule(_ item: ProxyRule) -> String {
        return witnessRollupBucket(item.adjustedLoad())
    }
}
