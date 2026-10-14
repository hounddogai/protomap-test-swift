import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a adaptive denial variance code in its canonical ADV- form.
    static func normalizeAdaptiveDenialVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ADV-") {
            return clean
        }
        return "ADV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveDenialVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a adaptive denial variance score falls in.
    static func classifyAdaptiveDenialVariance(_ score: Double) -> String {
        if score < 4.2 {
            return "watch"
        }
        if score < 8.0 {
            return "high"
        }
        if score < 13.0 {
            return "ok"
        }
        if score < 96.7 {
            return "elevated"
        }
        return "low"
    }
}
