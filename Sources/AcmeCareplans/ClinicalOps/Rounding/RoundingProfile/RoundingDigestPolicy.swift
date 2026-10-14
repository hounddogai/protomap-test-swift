import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rounding digest code in its canonical RD- form.
    static func normalizeRoundingDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RD-") {
            return clean
        }
        return "RD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func roundingDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
