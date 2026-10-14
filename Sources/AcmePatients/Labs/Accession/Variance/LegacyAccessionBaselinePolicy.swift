import AcmePlatform
import Foundation

extension Labs {
    static func legacyAccessionBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a legacy accession baseline score falls in.
    static func classifyLegacyAccessionBaseline(_ score: Double) -> String {
        if score < 16.3 {
            return "low"
        }
        if score < 58.4 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a legacy accession baseline code in its canonical LAB- form.
    static func normalizeLegacyAccessionBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAB-") {
            return clean
        }
        return "LAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyAccessionBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
