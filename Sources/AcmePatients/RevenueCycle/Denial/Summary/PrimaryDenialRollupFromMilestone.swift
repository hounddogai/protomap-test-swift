import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimMilestonesForRollup(_ items: [BatchedClaimMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePrimaryDenialRollupsFromMilestone(_ items: [BatchedClaimMilestone]) -> [PrimaryDenialRollup] {
        var out: [PrimaryDenialRollup] = []
        for item in items {
            let derived = newPrimaryDenialRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePrimaryDenialRollup(_ item: PrimaryDenialRollup) -> String {
        return classifyAdaptiveClaimTarget(item.projectedExposure())
    }
}
