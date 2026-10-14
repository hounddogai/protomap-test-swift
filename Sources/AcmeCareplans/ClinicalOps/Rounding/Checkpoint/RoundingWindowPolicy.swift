import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rounding window score falls in.
    static func classifyRoundingWindow(_ score: Double) -> String {
        if score < 18.4 {
            return "medium"
        }
        if score < 60.6 {
            return "low"
        }
        if score < 69.2 {
            return "minimal"
        }
        if score < 96.2 {
            return "elevated"
        }
        return "critical"
    }
}
