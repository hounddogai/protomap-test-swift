import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCredentialVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-credential-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalCredentialVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a seasonal credential variance score falls in.
    static func classifySeasonalCredentialVariance(_ score: Double) -> String {
        if score < 30.9 {
            return "minimal"
        }
        if score < 41.2 {
            return "watch"
        }
        if score < 43.7 {
            return "ok"
        }
        if score < 67.2 {
            return "critical"
        }
        return "low"
    }
}
