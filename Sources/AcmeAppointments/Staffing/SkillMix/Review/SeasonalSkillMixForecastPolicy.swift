import AcmePlatform
import Foundation

extension Staffing {
    static func seasonalSkillMixForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func seasonalSkillMixForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalSkillMixForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-skill-mix-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a seasonal skill mix forecast code in its canonical SSMF- form.
    static func normalizeSeasonalSkillMixForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSMF-") {
            return clean
        }
        return "SSMF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
