import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceProposalsForTier(_ items: [RemittanceProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveManualStatementTiersFromProposal(_ items: [RemittanceProposal]) -> [ManualStatementTier] {
        var out: [ManualStatementTier] = []
        for item in items {
            let derived = newManualStatementTier(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyManualStatementTierExtra(_ item: ManualStatementTier) -> String {
        return classifyRemittanceProposal(item.effectiveLoad())
    }
}
