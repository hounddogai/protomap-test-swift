import AcmePlatform
import Foundation

extension ClinicalOps {
    static func fallbackRoundingMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackRoundingMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-rounding-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback rounding metric code in its canonical FRM- form.
    static func normalizeFallbackRoundingMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRM-") {
            return clean
        }
        return "FRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback rounding metric score falls in.
    static func classifyFallbackRoundingMetric(_ score: Double) -> String {
        if score < 44.0 {
            return "ok"
        }
        if score < 44.4 {
            return "watch"
        }
        if score < 49.2 {
            return "medium"
        }
        if score < 54.1 {
            return "low"
        }
        return "minimal"
    }
}
