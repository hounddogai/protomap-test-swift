import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePendingCleaningPreferencesForSchedule(_ items: [PendingCleaningPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveBatchedCleaningSchedulesFromPreference(_ items: [PendingCleaningPreference]) -> [BatchedCleaningSchedule] {
        var out: [BatchedCleaningSchedule] = []
        for item in items {
            let derived = newBatchedCleaningSchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchBatchedCleaningSchedule(_ item: BatchedCleaningSchedule) -> Double {
        return cleaningCycleWeight(2, active: true)
    }
}
