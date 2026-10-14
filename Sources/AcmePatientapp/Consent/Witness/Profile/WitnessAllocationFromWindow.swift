import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureWindowsForAllocation(_ items: [DisclosureWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveWitnessAllocationsFromWindow(_ items: [DisclosureWindow]) -> [WitnessAllocation] {
        var out: [WitnessAllocation] = []
        for item in items {
            let derived = newWitnessAllocation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleWitnessAllocation(_ item: WitnessAllocation) -> Double {
        return disclosureWindowWeight(7, active: true)
    }
}
