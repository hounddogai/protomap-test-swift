import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a seasonal statement policy code in its canonical SSP- form.
    static func normalizeSeasonalStatementPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSP-") {
            return clean
        }
        return "SSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalStatementPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a seasonal statement policy score falls in.
    static func classifySeasonalStatementPolicy(_ score: Double) -> String {
        if score < 75.5 {
            return "medium"
        }
        if score < 83.1 {
            return "minimal"
        }
        return "watch"
    }
}
