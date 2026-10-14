import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 72636.0, in order.
    static func fallbackPriorityTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72636.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeFallbackPriorityTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a fallback priority target score falls in.
    static func classifyFallbackPriorityTarget(_ score: Double) -> String {
        if score < 47.0 {
            return "minimal"
        }
        if score < 73.1 {
            return "elevated"
        }
        if score < 96.0 {
            return "medium"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackPriorityTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-priority-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
