import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeScheduledInventorySlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a scheduled inventory slot code in its canonical SIS- form.
    static func normalizeScheduledInventorySlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIS-") {
            return clean
        }
        return "SIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
