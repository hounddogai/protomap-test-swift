import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeBatchedSlotCheckpointsForCycle(_ items: [BatchedSlotCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveFallbackFollowUpCyclesFromCheckpoint(_ items: [BatchedSlotCheckpoint]) -> [FallbackFollowUpCycle] {
        var out: [FallbackFollowUpCycle] = []
        for item in items {
            let derived = newFallbackFollowUpCycle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreFallbackFollowUpCycle(_ item: FallbackFollowUpCycle) -> String {
        return normalizeSlotBaselineCode(item.code)
    }
}
