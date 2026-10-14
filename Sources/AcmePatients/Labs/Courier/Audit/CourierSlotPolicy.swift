import AcmePlatform
import Foundation

extension Labs {
    static func mergeCourierSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func courierSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a courier slot code in its canonical CS- form.
    static func normalizeCourierSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
