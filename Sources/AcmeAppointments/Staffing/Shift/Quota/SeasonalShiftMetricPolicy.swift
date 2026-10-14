import AcmePlatform
import Foundation

extension Staffing {
    static func mergeSeasonalShiftMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalShiftMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-shift-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalShiftMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a seasonal shift metric code in its canonical SSM- form.
    static func normalizeSeasonalShiftMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSM-") {
            return clean
        }
        return "SSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
