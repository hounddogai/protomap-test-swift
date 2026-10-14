import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacySubstitutionLedgersForAllocation(_ items: [LegacySubstitutionLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveWeightedSubstitutionAllocationsFromLedger(_ items: [LegacySubstitutionLedger]) -> [WeightedSubstitutionAllocation] {
        var out: [WeightedSubstitutionAllocation] = []
        for item in items {
            let derived = newWeightedSubstitutionAllocation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeWeightedSubstitutionAllocation(_ item: WeightedSubstitutionAllocation) -> String {
        return normalizeGlobalSubstitutionTargetCode(item.code)
    }
}
