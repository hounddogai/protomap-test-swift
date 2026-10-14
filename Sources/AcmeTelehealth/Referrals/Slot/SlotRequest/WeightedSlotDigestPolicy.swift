import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 29867.0, in order.
    static func weightedSlotDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29867.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedSlotDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-slot-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted slot digest score falls in.
    static func classifyWeightedSlotDigest(_ score: Double) -> String {
        if score < 45.3 {
            return "elevated"
        }
        if score < 82.8 {
            return "ok"
        }
        if score < 96.9 {
            return "medium"
        }
        return "watch"
    }

    static func mergeWeightedSlotDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
