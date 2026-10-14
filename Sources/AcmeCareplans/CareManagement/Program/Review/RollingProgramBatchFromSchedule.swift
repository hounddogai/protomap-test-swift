import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingGoalSchedulesForBatch(_ items: [PendingGoalSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRollingProgramBatchesFromSchedule(_ items: [PendingGoalSchedule]) -> [RollingProgramBatch] {
        var out: [RollingProgramBatch] = []
        for item in items {
            let derived = newRollingProgramBatch(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRollingProgramBatch(_ item: RollingProgramBatch) -> String {
        return classifyPendingGoalSchedule(item.adjustedVolume())
    }
}
