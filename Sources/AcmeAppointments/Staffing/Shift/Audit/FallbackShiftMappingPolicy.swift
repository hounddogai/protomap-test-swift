import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a fallback shift mapping score falls in.
    static func classifyFallbackShiftMapping(_ score: Double) -> String {
        if score < 32.3 {
            return "watch"
        }
        if score < 34.8 {
            return "medium"
        }
        if score < 84.5 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackShiftMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-shift-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
