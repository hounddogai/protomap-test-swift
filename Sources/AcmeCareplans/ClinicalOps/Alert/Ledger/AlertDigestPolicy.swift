import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a alert digest score falls in.
    static func classifyAlertDigest(_ score: Double) -> String {
        if score < 22.5 {
            return "critical"
        }
        if score < 24.3 {
            return "watch"
        }
        return "ok"
    }
}
