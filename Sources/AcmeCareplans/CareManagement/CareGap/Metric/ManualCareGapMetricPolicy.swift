import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual care gap metric score falls in.
    static func classifyManualCareGapMetric(_ score: Double) -> String {
        if score < 16.5 {
            return "watch"
        }
        if score < 31.8 {
            return "low"
        }
        if score < 76.9 {
            return "high"
        }
        return "critical"
    }

    static func mergeManualCareGapMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func manualCareGapMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a manual care gap metric code in its canonical MCGM- form.
    static func normalizeManualCareGapMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCGM-") {
            return clean
        }
        return "MCGM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
