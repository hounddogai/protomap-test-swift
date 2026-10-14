import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedCredentialProfilesForAllocation(_ items: [WeightedCredentialProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveScheduledAcuityPlanAllocationsFromProfile(_ items: [WeightedCredentialProfile]) -> [ScheduledAcuityPlanAllocation] {
        var out: [ScheduledAcuityPlanAllocation] = []
        for item in items {
            let derived = newScheduledAcuityPlanAllocation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledAcuityPlanAllocation(_ item: ScheduledAcuityPlanAllocation) -> String {
        return pendingCredentialManifestBucket(item.measuredValue())
    }
}
