import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingSubstitutionRulesForGroup(_ items: [RollingSubstitutionRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveWeightedFormularyGroupsFromRule(_ items: [RollingSubstitutionRule]) -> [WeightedFormularyGroup] {
        var out: [WeightedFormularyGroup] = []
        for item in items {
            let derived = newWeightedFormularyGroup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileWeightedFormularyGroup(_ item: WeightedFormularyGroup) -> String {
        return normalizeSubstitutionLedgerCode(item.code)
    }
}
