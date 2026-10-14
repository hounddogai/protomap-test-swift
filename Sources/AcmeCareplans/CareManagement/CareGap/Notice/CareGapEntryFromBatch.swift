import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalBatchesForEntry(_ items: [GoalBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCareGapEntriesFromBatch(_ items: [GoalBatch]) -> [CareGapEntry] {
        var out: [CareGapEntry] = []
        for item in items {
            let derived = newCareGapEntry(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCareGapEntry(_ item: CareGapEntry) -> Double {
        return goalMappingWeight(3, active: true)
    }
}
