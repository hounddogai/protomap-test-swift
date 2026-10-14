import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAllocationsForCheckpoint(_ items: [ReadAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultWorklistCheckpointsFromAllocation(_ items: [ReadAllocation]) -> [DefaultWorklistCheckpoint] {
        var out: [DefaultWorklistCheckpoint] = []
        for item in items {
            let derived = newDefaultWorklistCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDefaultWorklistCheckpoint(_ item: DefaultWorklistCheckpoint) -> String {
        return readAdjustmentBucket(item.effectiveVolume())
    }
}
