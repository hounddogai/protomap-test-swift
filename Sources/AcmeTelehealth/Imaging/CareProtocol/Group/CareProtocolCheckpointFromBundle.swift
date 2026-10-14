import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityBundlesForCheckpoint(_ items: [PriorityBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCareProtocolCheckpointsFromBundle(_ items: [PriorityBundle]) -> [CareProtocolCheckpoint] {
        var out: [CareProtocolCheckpoint] = []
        for item in items {
            let derived = newCareProtocolCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCareProtocolCheckpoint(_ item: CareProtocolCheckpoint) -> Double {
        return priorityBundleWeight(9, active: true)
    }
}
