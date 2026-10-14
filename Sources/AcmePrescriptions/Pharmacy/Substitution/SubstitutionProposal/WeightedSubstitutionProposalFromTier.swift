import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyInteractionTiersForProposal(_ items: [LegacyInteractionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveWeightedSubstitutionProposalsFromTier(_ items: [LegacyInteractionTier]) -> [WeightedSubstitutionProposal] {
        var out: [WeightedSubstitutionProposal] = []
        for item in items {
            let derived = newWeightedSubstitutionProposal(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeWeightedSubstitutionProposal(_ item: WeightedSubstitutionProposal) -> String {
        return normalizeBatchedInteractionBudgetCode(item.code)
    }
}
