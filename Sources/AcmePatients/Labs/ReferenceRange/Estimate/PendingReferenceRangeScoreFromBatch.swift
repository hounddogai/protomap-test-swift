import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingAccessionBatchesForScore(_ items: [RollingAccessionBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePendingReferenceRangeScoresFromBatch(_ items: [RollingAccessionBatch]) -> [PendingReferenceRangeScore] {
        var out: [PendingReferenceRangeScore] = []
        for item in items {
            let derived = newPendingReferenceRangeScore(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingReferenceRangeScore(_ item: PendingReferenceRangeScore) -> String {
        return normalizeAccessionManifestCode(item.code)
    }
}
