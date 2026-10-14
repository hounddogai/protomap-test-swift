import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a float pool tier code in its canonical FPT- form.
    static func normalizeFloatPoolTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPT-") {
            return clean
        }
        return "FPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
