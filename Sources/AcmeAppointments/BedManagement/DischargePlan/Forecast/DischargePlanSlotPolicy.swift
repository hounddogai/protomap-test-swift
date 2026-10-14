import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a discharge plan slot code in its canonical DPS- form.
    static func normalizeDischargePlanSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPS-") {
            return clean
        }
        return "DPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dischargePlanSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
