import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRollingHandoffBaselinesForSlot(_ items: [RollingHandoffBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveBatchedRoundingSlotsFromBaseline(_ items: [RollingHandoffBaseline]) -> [BatchedRoundingSlot] {
        var out: [BatchedRoundingSlot] = []
        for item in items {
            let derived = newBatchedRoundingSlot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyBatchedRoundingSlot(_ item: BatchedRoundingSlot) -> String {
        return rollingHandoffBaselineBucket(item.effectiveTotal())
    }
}
