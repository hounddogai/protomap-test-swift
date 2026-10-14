import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction metric code in its canonical IM- form.
    static func normalizeInteractionMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IM-") {
            return clean
        }
        return "IM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeInteractionMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func interactionMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
