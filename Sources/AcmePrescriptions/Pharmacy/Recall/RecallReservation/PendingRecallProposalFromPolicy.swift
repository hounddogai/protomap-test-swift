import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryPoliciesForProposal(_ items: [InventoryPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePendingRecallProposalsFromPolicy(_ items: [InventoryPolicy]) -> [PendingRecallProposal] {
        var out: [PendingRecallProposal] = []
        for item in items {
            let derived = newPendingRecallProposal(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingRecallProposal(_ item: PendingRecallProposal) -> String {
        return normalizeCappedInventoryPreferenceCode(item.code)
    }
}
