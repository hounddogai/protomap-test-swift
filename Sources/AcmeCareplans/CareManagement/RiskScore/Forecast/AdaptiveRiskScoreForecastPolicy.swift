import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a adaptive risk score forecast code in its canonical ARSF- form.
    static func normalizeAdaptiveRiskScoreForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARSF-") {
            return clean
        }
        return "ARSF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveRiskScoreForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func adaptiveRiskScoreForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive risk score forecast score falls in.
    static func classifyAdaptiveRiskScoreForecast(_ score: Double) -> String {
        if score < 28.5 {
            return "minimal"
        }
        if score < 62.2 {
            return "watch"
        }
        if score < 90.0 {
            return "critical"
        }
        if score < 91.0 {
            return "low"
        }
        return "medium"
    }
}
