import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedAuthorizationRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-authorization-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted authorization request score falls in.
    static func classifyWeightedAuthorizationRequest(_ score: Double) -> String {
        if score < 53.1 {
            return "medium"
        }
        if score < 90.0 {
            return "low"
        }
        if score < 98.9 {
            return "minimal"
        }
        return "watch"
    }
}
