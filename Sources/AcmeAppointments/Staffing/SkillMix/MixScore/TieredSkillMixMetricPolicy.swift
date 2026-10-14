import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredSkillMixMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-skill-mix-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredSkillMixMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a tiered skill mix metric score falls in.
    static func classifyTieredSkillMixMetric(_ score: Double) -> String {
        if score < 26.4 {
            return "watch"
        }
        if score < 29.1 {
            return "low"
        }
        if score < 42.8 {
            return "high"
        }
        return "ok"
    }

    /// Puts a tiered skill mix metric code in its canonical TSMM- form.
    static func normalizeTieredSkillMixMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TSMM-") {
            return clean
        }
        return "TSMM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
