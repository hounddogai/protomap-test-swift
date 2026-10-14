import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistOverridesForCheckpoint(_ items: [WorklistOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePriorityCheckpointsFromOverride(_ items: [WorklistOverride]) -> [PriorityCheckpoint] {
        var out: [PriorityCheckpoint] = []
        for item in items {
            let derived = newPriorityCheckpoint(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPriorityCheckpoint(_ item: PriorityCheckpoint) -> String {
        return worklistOverrideBucket(item.projectedTotal())
    }
}
