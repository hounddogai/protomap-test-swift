import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementClaimsForMilestone(_ items: [StatementClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveLenientAuthorizationMilestonesFromClaim(_ items: [StatementClaim]) -> [LenientAuthorizationMilestone] {
        var out: [LenientAuthorizationMilestone] = []
        for item in items {
            let derived = newLenientAuthorizationMilestone(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientAuthorizationMilestone(_ item: LenientAuthorizationMilestone) -> String {
        return normalizeStatementTierCode(item.code)
    }
}
