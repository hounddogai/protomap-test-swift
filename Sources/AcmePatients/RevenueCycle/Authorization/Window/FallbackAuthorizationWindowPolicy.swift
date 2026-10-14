import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 7619.0, in order.
    static func fallbackAuthorizationWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7619.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackAuthorizationWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a fallback authorization window score falls in.
    static func classifyFallbackAuthorizationWindow(_ score: Double) -> String {
        if score < 40.9 {
            return "elevated"
        }
        if score < 81.2 {
            return "ok"
        }
        return "watch"
    }
}
