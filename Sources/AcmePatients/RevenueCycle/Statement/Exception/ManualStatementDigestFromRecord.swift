import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingClaimRecordsForDigest(_ items: [RollingClaimRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveManualStatementDigestsFromRecord(_ items: [RollingClaimRecord]) -> [ManualStatementDigest] {
        var out: [ManualStatementDigest] = []
        for item in items {
            let derived = newManualStatementDigest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceManualStatementDigest(_ item: ManualStatementDigest) -> String {
        return classifyRollingClaimRecord(item.measuredValue())
    }
}
