import AcmePlatform
import Foundation

extension ClinicalOps {
    static func batchedRoundingSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched rounding slot code in its canonical BRS- form.
    static func normalizeBatchedRoundingSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRS-") {
            return clean
        }
        return "BRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
