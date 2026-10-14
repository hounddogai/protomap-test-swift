import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a fallback denial forecast code in its canonical FDF- form.
    static func normalizeFallbackDenialForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDF-") {
            return clean
        }
        return "FDF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackDenialForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeFallbackDenialForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
