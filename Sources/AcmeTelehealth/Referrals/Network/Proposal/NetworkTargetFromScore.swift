import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacyNetworkScoresForTarget(_ items: [LegacyNetworkScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveNetworkTargetsFromScore(_ items: [LegacyNetworkScore]) -> [NetworkTarget] {
        var out: [NetworkTarget] = []
        for item in items {
            let derived = newNetworkTarget(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleNetworkTarget(_ item: NetworkTarget) -> Double {
        return legacyNetworkScoreWeight(5, active: true)
    }
}
