import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementProposalsForBundle(_ items: [StatementProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalClaimBundlesFromProposal(_ items: [StatementProposal]) -> [RegionalClaimBundle] {
        var out: [RegionalClaimBundle] = []
        for item in items {
            let derived = newRegionalClaimBundle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRegionalClaimBundle(_ item: RegionalClaimBundle) -> String {
        return classifySeasonalStatementPolicy(item.netExposure())
    }
}
