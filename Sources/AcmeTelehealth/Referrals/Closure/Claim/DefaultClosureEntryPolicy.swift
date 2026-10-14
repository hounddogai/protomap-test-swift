import AcmePlatform
import Foundation

extension Referrals {
    static func defaultClosureEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a default closure entry code in its canonical DCE- form.
    static func normalizeDefaultClosureEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCE-") {
            return clean
        }
        return "DCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
