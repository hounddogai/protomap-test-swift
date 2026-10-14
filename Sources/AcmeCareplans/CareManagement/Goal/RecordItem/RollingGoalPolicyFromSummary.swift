import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyGoalSummariesForPolicy(_ items: [LegacyGoalSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRollingGoalPoliciesFromSummary(_ items: [LegacyGoalSummary]) -> [RollingGoalPolicy] {
        var out: [RollingGoalPolicy] = []
        for item in items {
            let derived = newRollingGoalPolicy(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingGoalPolicy(_ item: RollingGoalPolicy) -> String {
        return scheduledGoalCheckpointBucket(item.projectedLoad())
    }
}
