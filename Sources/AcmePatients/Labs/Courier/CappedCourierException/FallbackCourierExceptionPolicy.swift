import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a fallback courier exception score falls in.
    static func classifyFallbackCourierException(_ score: Double) -> String {
        if score < 20.1 {
            return "medium"
        }
        if score < 65.6 {
            return "minimal"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCourierException() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-courier-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
