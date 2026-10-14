import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedProxyGroupsForScore(_ items: [WeightedProxyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDefaultProxyScoresFromGroup(_ items: [WeightedProxyGroup]) -> [DefaultProxyScore] {
        var out: [DefaultProxyScore] = []
        for item in items {
            let derived = newDefaultProxyScore(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankDefaultProxyScore(_ item: DefaultProxyScore) -> String {
        return weightedProxyGroupBucket(item.adjustedTotal())
    }
}
