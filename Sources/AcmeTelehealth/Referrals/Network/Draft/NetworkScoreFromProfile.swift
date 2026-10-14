import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralProfilesForScore(_ items: [ReferralProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveNetworkScoresFromProfile(_ items: [ReferralProfile]) -> [NetworkScore] {
        var out: [NetworkScore] = []
        for item in items {
            let derived = newNetworkScore(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyNetworkScore(_ item: NetworkScore) -> Double {
        return cappedReferralExceptionWeight(7, active: true)
    }
}
