import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeDigestsForClaim(_ items: [ChargeDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveStatementClaimsFromDigest(_ items: [ChargeDigest]) -> [StatementClaim] {
        var out: [StatementClaim] = []
        for item in items {
            let derived = newStatementClaim(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStatementClaim(_ item: StatementClaim) -> String {
        return classifyChargeBudget(item.adjustedVolume())
    }
}
