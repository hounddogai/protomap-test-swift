import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding segment score falls in.
    static func classifyRoundingSegment(_ score: Double) -> String {
        if score < 10.1 {
            return "ok"
        }
        if score < 86.5 {
            return "minimal"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
