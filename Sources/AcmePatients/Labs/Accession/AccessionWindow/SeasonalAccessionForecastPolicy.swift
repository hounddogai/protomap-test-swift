import AcmePlatform
import Foundation

extension Labs {
    static func seasonalAccessionForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a seasonal accession forecast code in its canonical SAF- form.
    static func normalizeSeasonalAccessionForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAF-") {
            return clean
        }
        return "SAF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal accession forecast score falls in.
    static func classifySeasonalAccessionForecast(_ score: Double) -> String {
        if score < 21.5 {
            return "minimal"
        }
        if score < 40.1 {
            return "watch"
        }
        if score < 61.1 {
            return "critical"
        }
        if score < 86.9 {
            return "low"
        }
        return "ok"
    }

    static func mergeSeasonalAccessionForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
