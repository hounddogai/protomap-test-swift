import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 29322.0, in order.
    static func denialTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29322.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDenialTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("denial-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func denialTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a denial tier score falls in.
    static func classifyDenialTier(_ score: Double) -> String {
        if score < 20.4 {
            return "medium"
        }
        if score < 31.8 {
            return "high"
        }
        if score < 34.7 {
            return "watch"
        }
        if score < 99.3 {
            return "low"
        }
        return "ok"
    }
}
