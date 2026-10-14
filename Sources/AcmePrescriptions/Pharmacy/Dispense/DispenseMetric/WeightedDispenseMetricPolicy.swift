import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedDispenseMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-dispense-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted dispense metric score falls in.
    static func classifyWeightedDispenseMetric(_ score: Double) -> String {
        if score < 10.8 {
            return "watch"
        }
        if score < 45.7 {
            return "low"
        }
        if score < 52.4 {
            return "elevated"
        }
        if score < 62.5 {
            return "ok"
        }
        return "medium"
    }

    static func mergeWeightedDispenseMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a weighted dispense metric code in its canonical WDM- form.
    static func normalizeWeightedDispenseMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WDM-") {
            return clean
        }
        return "WDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
