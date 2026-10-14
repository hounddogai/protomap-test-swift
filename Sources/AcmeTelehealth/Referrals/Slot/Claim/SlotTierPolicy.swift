import AcmePlatform
import Foundation

extension Referrals {
    static func mergeSlotTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 19297.0, in order.
    static func slotTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19297.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a slot tier score falls in.
    static func classifySlotTier(_ score: Double) -> String {
        if score < 14.7 {
            return "elevated"
        }
        if score < 20.5 {
            return "critical"
        }
        if score < 37.0 {
            return "medium"
        }
        return "ok"
    }
}
