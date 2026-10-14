import AcmePlatform
import Foundation

extension Consent {
    static func cappedRevocationAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a capped revocation adjustment code in its canonical CRA- form.
    static func normalizeCappedRevocationAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRA-") {
            return clean
        }
        return "CRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped revocation adjustment score falls in.
    static func classifyCappedRevocationAdjustment(_ score: Double) -> String {
        if score < 44.2 {
            return "medium"
        }
        if score < 67.8 {
            return "low"
        }
        if score < 88.1 {
            return "ok"
        }
        return "critical"
    }
}
