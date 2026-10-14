import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a batched census budget score falls in.
    static func classifyBatchedCensusBudget(_ score: Double) -> String {
        if score < 20.6 {
            return "elevated"
        }
        if score < 30.4 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a batched census budget code in its canonical BCB- form.
    static func normalizeBatchedCensusBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCB-") {
            return clean
        }
        return "BCB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedCensusBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedCensusBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
