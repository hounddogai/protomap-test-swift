import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a legacy follow up adjustment code in its canonical LFUA- form.
    static func normalizeLegacyFollowUpAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LFUA-") {
            return clean
        }
        return "LFUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyFollowUpAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a legacy follow up adjustment score falls in.
    static func classifyLegacyFollowUpAdjustment(_ score: Double) -> String {
        if score < 37.2 {
            return "high"
        }
        if score < 54.1 {
            return "elevated"
        }
        if score < 56.8 {
            return "low"
        }
        if score < 62.6 {
            return "ok"
        }
        return "critical"
    }
}
