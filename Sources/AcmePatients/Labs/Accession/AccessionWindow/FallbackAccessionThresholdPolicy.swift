import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackAccessionThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-accession-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackAccessionThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a fallback accession threshold score falls in.
    static func classifyFallbackAccessionThreshold(_ score: Double) -> String {
        if score < 1.6 {
            return "watch"
        }
        if score < 99.9 {
            return "minimal"
        }
        return "low"
    }

    static func fallbackAccessionThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
