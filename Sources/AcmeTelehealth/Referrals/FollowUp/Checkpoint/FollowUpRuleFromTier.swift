import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkTiersForRule(_ items: [NetworkTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveFollowUpRulesFromTier(_ items: [NetworkTier]) -> [FollowUpRule] {
        var out: [FollowUpRule] = []
        for item in items {
            let derived = newFollowUpRule(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceFollowUpRule(_ item: FollowUpRule) -> String {
        return normalizeNetworkTierCode(item.code)
    }
}
