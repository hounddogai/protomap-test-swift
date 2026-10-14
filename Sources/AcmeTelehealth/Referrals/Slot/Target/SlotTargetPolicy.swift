import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot target code in its canonical ST- form.
    static func normalizeSlotTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ST-") {
            return clean
        }
        return "ST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func slotTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
