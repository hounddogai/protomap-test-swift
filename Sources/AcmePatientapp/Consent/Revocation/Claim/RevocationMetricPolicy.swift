import AcmePlatform
import Foundation

extension Consent {
    static func revocationMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation metric score falls in.
    static func classifyRevocationMetric(_ score: Double) -> String {
        if score < 25.2 {
            return "ok"
        }
        if score < 40.6 {
            return "watch"
        }
        if score < 52.4 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a revocation metric code in its canonical RM- form.
    static func normalizeRevocationMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RM-") {
            return clean
        }
        return "RM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
