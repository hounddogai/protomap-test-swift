import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeScheduledInventoryCheckpointsForGroup(_ items: [ScheduledInventoryCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveDispenseGroupsFromCheckpoint(_ items: [ScheduledInventoryCheckpoint]) -> [DispenseGroup] {
        var out: [DispenseGroup] = []
        for item in items {
            let derived = newDispenseGroup(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateDispenseGroup(_ item: DispenseGroup) -> Double {
        return globalInventoryThresholdWeight(9, active: true)
    }
}
