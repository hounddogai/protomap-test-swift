import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveFormularyMilestonesForAllocation(_ items: [AdaptiveFormularyMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func derivePendingFormularyAllocationsFromMilestone(_ items: [AdaptiveFormularyMilestone]) -> [PendingFormularyAllocation] {
        var out: [PendingFormularyAllocation] = []
        for item in items {
            let derived = newPendingFormularyAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingFormularyAllocation(_ item: PendingFormularyAllocation) -> Double {
        return manualFormularyDigestWeight(1, active: true)
    }
}
