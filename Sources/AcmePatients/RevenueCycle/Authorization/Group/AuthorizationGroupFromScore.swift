import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementScoresForGroup(_ items: [StatementScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAuthorizationGroupsFromScore(_ items: [StatementScore]) -> [AuthorizationGroup] {
        var out: [AuthorizationGroup] = []
        for item in items {
            let derived = newAuthorizationGroup(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreAuthorizationGroup(_ item: AuthorizationGroup) -> Double {
        return lenientStatementMilestoneWeight(5, active: true)
    }
}
