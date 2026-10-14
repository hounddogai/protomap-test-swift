import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a scheduled follow up group code in its canonical SFUG- form.
    static func normalizeScheduledFollowUpGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUG-") {
            return clean
        }
        return "SFUG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledFollowUpGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func scheduledFollowUpGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
