import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan adjustment code in its canonical DPA- form.
    static func normalizeDischargePlanAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPA-") {
            return clean
        }
        return "DPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a discharge plan adjustment score falls in.
    static func classifyDischargePlanAdjustment(_ score: Double) -> String {
        if score < 30.5 {
            return "elevated"
        }
        if score < 80.6 {
            return "low"
        }
        if score < 83.6 {
            return "watch"
        }
        return "high"
    }
}
