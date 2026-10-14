import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultRemittanceTargetsForAllocation(_ items: [DefaultRemittanceTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveStrictRemittanceAllocationsFromTarget(_ items: [DefaultRemittanceTarget]) -> [StrictRemittanceAllocation] {
        var out: [StrictRemittanceAllocation] = []
        for item in items {
            let derived = newStrictRemittanceAllocation(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateStrictRemittanceAllocation(_ item: StrictRemittanceAllocation) -> String {
        return normalizeSeasonalRemittanceGroupCode(item.code)
    }
}
