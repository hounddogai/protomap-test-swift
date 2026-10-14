import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a batched discharge plan metric code in its canonical BDPM- form.
    static func normalizeBatchedDischargePlanMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDPM-") {
            return clean
        }
        return "BDPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedDischargePlanMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeBatchedDischargePlanMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
