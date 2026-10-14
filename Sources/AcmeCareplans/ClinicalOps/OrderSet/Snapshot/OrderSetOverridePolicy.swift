import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set override code in its canonical OSO- form.
    static func normalizeOrderSetOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSO-") {
            return clean
        }
        return "OSO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func orderSetOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeOrderSetOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
