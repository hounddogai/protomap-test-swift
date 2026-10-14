import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkMilestonesForProposal(_ items: [NetworkMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveClosureProposalsFromMilestone(_ items: [NetworkMilestone]) -> [ClosureProposal] {
        var out: [ClosureProposal] = []
        for item in items {
            let derived = newClosureProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleClosureProposal(_ item: ClosureProposal) -> String {
        return classifyLenientNetworkScore(item.effectiveExposure())
    }
}
