import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a overtime cycle score falls in.
    static func classifyOvertimeCycle(_ score: Double) -> String {
        if score < 49.3 {
            return "watch"
        }
        if score < 81.4 {
            return "critical"
        }
        if score < 87.3 {
            return "low"
        }
        return "ok"
    }

    static func mergeOvertimeCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 43454.0, in order.
    static func overtimeCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43454.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
