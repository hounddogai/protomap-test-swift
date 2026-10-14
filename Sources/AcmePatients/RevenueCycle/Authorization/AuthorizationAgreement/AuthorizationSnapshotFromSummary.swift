import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeWeightedStatementSummariesForSnapshot(_ items: [WeightedStatementSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationSnapshotsFromSummary(_ items: [WeightedStatementSummary]) -> [AuthorizationSnapshot] {
        var out: [AuthorizationSnapshot] = []
        for item in items {
            let derived = newAuthorizationSnapshot(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAuthorizationSnapshot(_ item: AuthorizationSnapshot) -> String {
        return weightedStatementSummaryBucket(item.effectiveExposure())
    }
}
