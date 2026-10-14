import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a tiered read batch code in its canonical TRB- form.
    static func normalizeTieredReadBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRB-") {
            return clean
        }
        return "TRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredReadBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
