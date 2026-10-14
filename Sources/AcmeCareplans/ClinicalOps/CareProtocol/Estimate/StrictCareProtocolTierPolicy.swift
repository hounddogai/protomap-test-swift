import AcmePlatform
import Foundation

extension ClinicalOps {
    static func strictCareProtocolTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a strict care protocol tier code in its canonical SCPT- form.
    static func normalizeStrictCareProtocolTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPT-") {
            return clean
        }
        return "SCPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
