import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimaryInventoryOverridesForProposal(_ items: [PrimaryInventoryOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFallbackFormularyProposalsFromOverride(_ items: [PrimaryInventoryOverride]) -> [FallbackFormularyProposal] {
        var out: [FallbackFormularyProposal] = []
        for item in items {
            let derived = newFallbackFormularyProposal(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackFormularyProposal(_ item: FallbackFormularyProposal) -> String {
        return lenientInventoryProposalBucket(item.netTotal())
    }
}
