import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedProxyGroupsForAssignment(_ items: [WeightedProxyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveRollingWitnessAssignmentsFromGroup(_ items: [WeightedProxyGroup]) -> [RollingWitnessAssignment] {
        var out: [RollingWitnessAssignment] = []
        for item in items {
            let derived = newRollingWitnessAssignment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingWitnessAssignment(_ item: RollingWitnessAssignment) -> String {
        return classifyWeightedProxyGroup(item.projectedVolume())
    }
}
