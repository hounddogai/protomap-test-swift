import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a regional alert forecast code in its canonical RAF- form.
    static func normalizeRegionalAlertForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAF-") {
            return clean
        }
        return "RAF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalAlertForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalAlertForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a regional alert forecast score falls in.
    static func classifyRegionalAlertForecast(_ score: Double) -> String {
        if score < 13.2 {
            return "watch"
        }
        if score < 25.9 {
            return "elevated"
        }
        if score < 68.4 {
            return "minimal"
        }
        if score < 69.2 {
            return "low"
        }
        return "ok"
    }
}
