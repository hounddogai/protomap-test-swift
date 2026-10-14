import AcmePlatform
import Foundation

extension BedManagement {
    static func manualCensusForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a manual census forecast score falls in.
    static func classifyManualCensusForecast(_ score: Double) -> String {
        if score < 5.2 {
            return "elevated"
        }
        if score < 55.7 {
            return "ok"
        }
        if score < 58.9 {
            return "high"
        }
        if score < 91.9 {
            return "medium"
        }
        return "minimal"
    }

    static func mergeManualCensusForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual census forecast code in its canonical MCF- form.
    static func normalizeManualCensusForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCF-") {
            return clean
        }
        return "MCF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
