import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackChargeEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-charge-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback charge entry score falls in.
    static func classifyFallbackChargeEntry(_ score: Double) -> String {
        if score < 18.3 {
            return "critical"
        }
        if score < 30.7 {
            return "ok"
        }
        if score < 89.8 {
            return "watch"
        }
        return "high"
    }
}
