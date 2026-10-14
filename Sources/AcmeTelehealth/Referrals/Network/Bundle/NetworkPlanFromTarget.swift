import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeCappedFollowUpTargetsForPlan(_ items: [CappedFollowUpTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveNetworkPlansFromTarget(_ items: [CappedFollowUpTarget]) -> [NetworkPlan] {
        var out: [NetworkPlan] = []
        for item in items {
            let derived = newNetworkPlan(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleNetworkPlan(_ item: NetworkPlan) -> String {
        return normalizeCappedFollowUpTargetCode(item.code)
    }
}
