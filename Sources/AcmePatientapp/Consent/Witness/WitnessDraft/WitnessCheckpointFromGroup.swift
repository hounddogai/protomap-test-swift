import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationGroupsForCheckpoint(_ items: [ScheduledRevocationGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWitnessCheckpointsFromGroup(_ items: [ScheduledRevocationGroup]) -> [WitnessCheckpoint] {
        var out: [WitnessCheckpoint] = []
        for item in items {
            let derived = newWitnessCheckpoint(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignWitnessCheckpoint(_ item: WitnessCheckpoint) -> Double {
        return revocationAllocationWeight(1, active: true)
    }
}
