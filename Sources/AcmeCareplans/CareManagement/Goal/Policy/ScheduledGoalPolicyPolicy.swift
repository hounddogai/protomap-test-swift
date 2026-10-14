import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledGoalPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a scheduled goal policy code in its canonical SGP- form.
    static func normalizeScheduledGoalPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SGP-") {
            return clean
        }
        return "SGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
