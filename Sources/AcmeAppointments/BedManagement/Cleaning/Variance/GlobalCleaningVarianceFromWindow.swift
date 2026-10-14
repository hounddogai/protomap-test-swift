import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedIsolationWindowsForVariance(_ items: [BatchedIsolationWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalCleaningVariancesFromWindow(_ items: [BatchedIsolationWindow]) -> [GlobalCleaningVariance] {
        var out: [GlobalCleaningVariance] = []
        for item in items {
            let derived = newGlobalCleaningVariance(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitGlobalCleaningVariance(_ item: GlobalCleaningVariance) -> String {
        return manualIsolationPreferenceBucket(item.weightedLoad())
    }
}
