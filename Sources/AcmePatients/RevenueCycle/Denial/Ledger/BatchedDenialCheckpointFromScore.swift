import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceScoresForCheckpoint(_ items: [RemittanceScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveBatchedDenialCheckpointsFromScore(_ items: [RemittanceScore]) -> [BatchedDenialCheckpoint] {
        var out: [BatchedDenialCheckpoint] = []
        for item in items {
            let derived = newBatchedDenialCheckpoint(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeBatchedDenialCheckpoint(_ item: BatchedDenialCheckpoint) -> String {
        return classifyFallbackRemittanceTarget(item.measuredValue())
    }
}
