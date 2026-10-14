import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledCleaningThresholdsForAllocation(_ items: [ScheduledCleaningThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualCensusAllocationsFromThreshold(_ items: [ScheduledCleaningThreshold]) -> [ManualCensusAllocation] {
        var out: [ManualCensusAllocation] = []
        for item in items {
            let derived = newManualCensusAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualCensusAllocation(_ item: ManualCensusAllocation) -> Double {
        return scheduledCleaningThresholdWeight(2, active: true)
    }
}
