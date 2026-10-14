import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffAllocationsForProposal(_ items: [HandoffAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLegacyOrderSetProposalsFromAllocation(_ items: [HandoffAllocation]) -> [LegacyOrderSetProposal] {
        var out: [LegacyOrderSetProposal] = []
        for item in items {
            let derived = newLegacyOrderSetProposal(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }
}
