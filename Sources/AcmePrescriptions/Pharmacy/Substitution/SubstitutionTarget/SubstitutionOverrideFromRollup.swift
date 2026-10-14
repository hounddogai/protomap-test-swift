import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedFormularyRollupsForOverride(_ items: [WeightedFormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveSubstitutionOverridesFromRollup(_ items: [WeightedFormularyRollup]) -> [SubstitutionOverride] {
        var out: [SubstitutionOverride] = []
        for item in items {
            let derived = newSubstitutionOverride(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeSubstitutionOverride(_ item: SubstitutionOverride) -> Double {
        return tieredFormularyRollupWeight(1, active: true)
    }
}
