import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeGlobalSlotAdjustmentsForProposal(_ items: [GlobalSlotAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveNetworkProposalsFromAdjustment(_ items: [GlobalSlotAdjustment]) -> [NetworkProposal] {
        var out: [NetworkProposal] = []
        for item in items {
            let derived = newNetworkProposal(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveNetworkProposal(_ item: NetworkProposal) -> String {
        return cappedSlotProfileBucket(item.netTotal())
    }
}
