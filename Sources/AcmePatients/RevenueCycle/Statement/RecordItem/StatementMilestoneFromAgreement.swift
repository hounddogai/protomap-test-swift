import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimAgreementsForMilestone(_ items: [BatchedClaimAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveStatementMilestonesFromAgreement(_ items: [BatchedClaimAgreement]) -> [StatementMilestone] {
        var out: [StatementMilestone] = []
        for item in items {
            let derived = newStatementMilestone(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceStatementMilestone(_ item: StatementMilestone) -> String {
        return claimRollupBucket(item.measuredValue())
    }
}
