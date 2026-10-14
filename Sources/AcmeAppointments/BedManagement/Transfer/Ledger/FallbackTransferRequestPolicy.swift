import AcmePlatform
import Foundation

extension BedManagement {
    static func fallbackTransferRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a fallback transfer request code in its canonical FTR- form.
    static func normalizeFallbackTransferRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FTR-") {
            return clean
        }
        return "FTR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
