import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredModalityProfilesForProfile(_ items: [TieredModalityProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedPriorityProfilesFromProfile(_ items: [TieredModalityProfile]) -> [BatchedPriorityProfile] {
        var out: [BatchedPriorityProfile] = []
        for item in items {
            let derived = newBatchedPriorityProfile(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeBatchedPriorityProfile(_ item: BatchedPriorityProfile) -> Double {
        return tieredModalityProfileWeight(7, active: true)
    }
}
