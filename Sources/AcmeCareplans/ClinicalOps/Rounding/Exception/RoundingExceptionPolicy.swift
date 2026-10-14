import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingException() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rounding exception score falls in.
    static func classifyRoundingException(_ score: Double) -> String {
        if score < 30.4 {
            return "critical"
        }
        if score < 86.5 {
            return "elevated"
        }
        return "minimal"
    }
}
