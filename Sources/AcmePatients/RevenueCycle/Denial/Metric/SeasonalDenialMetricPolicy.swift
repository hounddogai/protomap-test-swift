import AcmePlatform
import Foundation

extension RevenueCycle {
    static func seasonalDenialMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal denial metric score falls in.
    static func classifySeasonalDenialMetric(_ score: Double) -> String {
        if score < 38.8 {
            return "low"
        }
        if score < 50.0 {
            return "medium"
        }
        return "minimal"
    }

    /// Puts a seasonal denial metric code in its canonical SDM- form.
    static func normalizeSeasonalDenialMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDM-") {
            return clean
        }
        return "SDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
