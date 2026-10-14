import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingReferenceRangeOverridesForBatch(_ items: [PendingReferenceRangeOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingAccessionBatchesFromOverride(_ items: [PendingReferenceRangeOverride]) -> [RollingAccessionBatch] {
        var out: [RollingAccessionBatch] = []
        for item in items {
            let derived = newRollingAccessionBatch(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingAccessionBatch(_ item: RollingAccessionBatch) -> String {
        return normalizeReferenceRangeWindowCode(item.code)
    }
}
