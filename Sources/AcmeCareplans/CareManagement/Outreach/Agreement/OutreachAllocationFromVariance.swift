import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledCareGapVariancesForAllocation(_ items: [ScheduledCareGapVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveOutreachAllocationsFromVariance(_ items: [ScheduledCareGapVariance]) -> [OutreachAllocation] {
        var out: [OutreachAllocation] = []
        for item in items {
            let derived = newOutreachAllocation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitOutreachAllocation(_ item: OutreachAllocation) -> String {
        return normalizeScheduledCareGapVarianceCode(item.code)
    }
}
