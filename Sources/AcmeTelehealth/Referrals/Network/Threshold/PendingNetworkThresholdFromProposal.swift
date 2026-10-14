import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotProposalsForThreshold(_ items: [SlotProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingNetworkThresholdsFromProposal(_ items: [SlotProposal]) -> [PendingNetworkThreshold] {
        var out: [PendingNetworkThreshold] = []
        for item in items {
            let derived = newPendingNetworkThreshold(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePendingNetworkThreshold(_ item: PendingNetworkThreshold) -> String {
        return normalizeSlotScoreCode(item.code)
    }
}
