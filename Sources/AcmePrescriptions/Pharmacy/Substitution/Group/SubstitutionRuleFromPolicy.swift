import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedDispensePoliciesForRule(_ items: [BatchedDispensePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSubstitutionRulesFromPolicy(_ items: [BatchedDispensePolicy]) -> [SubstitutionRule] {
        var out: [SubstitutionRule] = []
        for item in items {
            let derived = newSubstitutionRule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeSubstitutionRule(_ item: SubstitutionRule) -> String {
        return classifyDispenseRequest(item.effectiveVolume())
    }
}
