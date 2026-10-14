import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallProfilesForAllocation(_ items: [RecallProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFormularyAllocationsFromProfile(_ items: [RecallProfile]) -> [FormularyAllocation] {
        var out: [FormularyAllocation] = []
        for item in items {
            let derived = newFormularyAllocation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFormularyAllocation(_ item: FormularyAllocation) -> String {
        return recallRollupBucket(item.netExposure())
    }
}
