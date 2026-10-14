import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalClosureWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-closure-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a seasonal closure window score falls in.
    static func classifySeasonalClosureWindow(_ score: Double) -> String {
        if score < 9.4 {
            return "high"
        }
        if score < 86.6 {
            return "critical"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 55710.0, in order.
    static func seasonalClosureWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55710.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeSeasonalClosureWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
