import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a accession segment score falls in.
    static func classifyAccessionSegment(_ score: Double) -> String {
        if score < 9.4 {
            return "critical"
        }
        if score < 68.1 {
            return "ok"
        }
        return "elevated"
    }

    static func accessionSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
