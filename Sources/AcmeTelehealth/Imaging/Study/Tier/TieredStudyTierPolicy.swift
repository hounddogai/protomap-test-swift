import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a tiered study tier code in its canonical TST- form.
    static func normalizeTieredStudyTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TST-") {
            return clean
        }
        return "TST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredStudyTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
