import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultBaselinesForCheckpoint(_ items: [ResultBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRollingAccessionCheckpointsFromBaseline(_ items: [ResultBaseline]) -> [RollingAccessionCheckpoint] {
        var out: [RollingAccessionCheckpoint] = []
        for item in items {
            let derived = newRollingAccessionCheckpoint(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRollingAccessionCheckpoint(_ item: RollingAccessionCheckpoint) -> Double {
        return globalResultSlotWeight(1, active: true)
    }
}
