import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a capped discharge plan item code in its canonical CDPI- form.
    static func normalizeCappedDischargePlanItemCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CDPI-") {
            return clean
        }
        return "CDPI-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedDischargePlanItemWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
