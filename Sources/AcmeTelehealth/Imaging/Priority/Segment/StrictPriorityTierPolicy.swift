import AcmePlatform
import Foundation

extension Imaging {
    static func strictPriorityTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a strict priority tier code in its canonical SPT- form.
    static func normalizeStrictPriorityTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPT-") {
            return clean
        }
        return "SPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
