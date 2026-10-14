import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback courier slot code in its canonical FCS- form.
    static func normalizeFallbackCourierSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCS-") {
            return clean
        }
        return "FCS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackCourierSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeFallbackCourierSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
