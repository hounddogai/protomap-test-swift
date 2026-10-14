import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualCensusAllocationsForBatch(_ items: [ManualCensusAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveCensusBatchesFromAllocation(_ items: [ManualCensusAllocation]) -> [AdaptiveCensusBatch] {
        var out: [AdaptiveCensusBatch] = []
        for item in items {
            let derived = newAdaptiveCensusBatch(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveAdaptiveCensusBatch(_ item: AdaptiveCensusBatch) -> String {
        return censusPolicyBucket(item.effectiveLoad())
    }
}
