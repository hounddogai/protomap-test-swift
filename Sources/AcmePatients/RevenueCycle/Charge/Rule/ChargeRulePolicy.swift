import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a charge rule score falls in.
    static func classifyChargeRule(_ score: Double) -> String {
        if score < 12.4 {
            return "elevated"
        }
        if score < 48.7 {
            return "medium"
        }
        return "minimal"
    }

    /// Puts a charge rule code in its canonical CR- form.
    static func normalizeChargeRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func chargeRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
