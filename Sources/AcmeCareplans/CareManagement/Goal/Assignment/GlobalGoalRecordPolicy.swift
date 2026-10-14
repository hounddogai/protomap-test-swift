import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a global goal record code in its canonical GGR- form.
    static func normalizeGlobalGoalRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GGR-") {
            return clean
        }
        return "GGR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalGoalRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeGlobalGoalRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
