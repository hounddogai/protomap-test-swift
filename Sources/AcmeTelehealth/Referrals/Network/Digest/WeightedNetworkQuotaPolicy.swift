import AcmePlatform
import Foundation

extension Referrals {
    static func mergeWeightedNetworkQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedNetworkQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-network-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted network quota score falls in.
    static func classifyWeightedNetworkQuota(_ score: Double) -> String {
        if score < 75.7 {
            return "watch"
        }
        if score < 89.6 {
            return "low"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 3288.0, in order.
    static func weightedNetworkQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3288.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
