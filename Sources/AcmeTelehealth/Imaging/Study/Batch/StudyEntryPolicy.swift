import AcmePlatform
import Foundation

extension Imaging {
    static func studyEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a study entry code in its canonical SE- form.
    static func normalizeStudyEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SE-") {
            return clean
        }
        return "SE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
