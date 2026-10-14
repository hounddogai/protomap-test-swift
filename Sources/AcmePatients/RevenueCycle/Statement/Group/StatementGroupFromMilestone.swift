import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationMilestonesForGroup(_ items: [AuthorizationMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveStatementGroupsFromMilestone(_ items: [AuthorizationMilestone]) -> [StatementGroup] {
        var out: [StatementGroup] = []
        for item in items {
            let derived = newStatementGroup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyStatementGroupExtra(_ item: StatementGroup) -> String {
        return authorizationAssignmentBucket(item.measuredValue())
    }
}
