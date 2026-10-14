import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a lenient authorization variance score falls in.
    static func classifyLenientAuthorizationVariance(_ score: Double) -> String {
        if score < 32.3 {
            return "medium"
        }
        if score < 59.8 {
            return "high"
        }
        if score < 70.1 {
            return "elevated"
        }
        if score < 83.8 {
            return "watch"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientAuthorizationVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-authorization-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
