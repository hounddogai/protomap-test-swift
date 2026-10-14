import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledAcuityPlanRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a scheduled acuity plan rule code in its canonical SAPR- form.
    static func normalizeScheduledAcuityPlanRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAPR-") {
            return clean
        }
        return "SAPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
