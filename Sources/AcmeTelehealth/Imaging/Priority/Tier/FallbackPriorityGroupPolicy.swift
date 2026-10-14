import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a fallback priority group score falls in.
    static func classifyFallbackPriorityGroup(_ score: Double) -> String {
        if score < 13.8 {
            return "low"
        }
        if score < 85.4 {
            return "minimal"
        }
        if score < 87.5 {
            return "elevated"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackPriorityGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-priority-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackPriorityGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 43835.0, in order.
    static func fallbackPriorityGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43835.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
