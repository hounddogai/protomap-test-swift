import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedCleaningScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a capped cleaning score score falls in.
    static func classifyCappedCleaningScore(_ score: Double) -> String {
        if score < 48.8 {
            return "low"
        }
        if score < 87.6 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a capped cleaning score code in its canonical CCS- form.
    static func normalizeCappedCleaningScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCS-") {
            return clean
        }
        return "CCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedCleaningScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
