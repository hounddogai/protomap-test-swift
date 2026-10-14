import AcmePlatform
import Foundation

extension Consent {
    static func summarizePendingWitnessSummariesForMilestone(_ items: [PendingWitnessSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTieredProxyMilestonesFromSummary(_ items: [PendingWitnessSummary]) -> [TieredProxyMilestone] {
        var out: [TieredProxyMilestone] = []
        for item in items {
            let derived = newTieredProxyMilestone(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileTieredProxyMilestone(_ item: TieredProxyMilestone) -> Double {
        return defaultWitnessBaselineWeight(4, active: true)
    }
}
