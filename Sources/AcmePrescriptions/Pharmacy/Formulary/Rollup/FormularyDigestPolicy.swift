import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a formulary digest score falls in.
    static func classifyFormularyDigest(_ score: Double) -> String {
        if score < 24.8 {
            return "critical"
        }
        if score < 77.6 {
            return "low"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFormularyDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("formulary-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
