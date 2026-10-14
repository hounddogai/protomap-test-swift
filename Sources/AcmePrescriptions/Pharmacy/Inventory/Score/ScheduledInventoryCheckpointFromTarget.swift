import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedSubstitutionTargetsForCheckpoint(_ items: [BatchedSubstitutionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveScheduledInventoryCheckpointsFromTarget(_ items: [BatchedSubstitutionTarget]) -> [ScheduledInventoryCheckpoint] {
        var out: [ScheduledInventoryCheckpoint] = []
        for item in items {
            let derived = newScheduledInventoryCheckpoint(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledInventoryCheckpoint(_ item: ScheduledInventoryCheckpoint) -> String {
        return classifyBatchedSubstitutionTarget(item.weightedExposure())
    }
}
