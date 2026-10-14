import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualNetworkCyclesForProposal(_ items: [ManualNetworkCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFollowUpProposalsFromCycle(_ items: [ManualNetworkCycle]) -> [FollowUpProposal] {
        var out: [FollowUpProposal] = []
        for item in items {
            let derived = newFollowUpProposal(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFollowUpProposal(_ item: FollowUpProposal) -> String {
        return classifyAdaptiveNetworkBundle(item.adjustedLoad())
    }
}
