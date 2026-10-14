import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive goal preference score falls in.
    static func classifyAdaptiveGoalPreference(_ score: Double) -> String {
        if score < 5.6 {
            return "critical"
        }
        if score < 26.5 {
            return "minimal"
        }
        if score < 54.2 {
            return "watch"
        }
        return "medium"
    }

    static func adaptiveGoalPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive goal preference code in its canonical AGP- form.
    static func normalizeAdaptiveGoalPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AGP-") {
            return clean
        }
        return "AGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveGoalPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
