import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict revocation batch code in its canonical SRB- form.
    static func normalizeStrictRevocationBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRB-") {
            return clean
        }
        return "SRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictRevocationBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
