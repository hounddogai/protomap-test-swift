import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDefaultDispenseAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func defaultDispenseAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a default dispense adjustment code in its canonical DDA- form.
    static func normalizeDefaultDispenseAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DDA-") {
            return clean
        }
        return "DDA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
