import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a goal budget code in its canonical GB- form.
    static func normalizeGoalBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GB-") {
            return clean
        }
        return "GB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGoalBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func goalBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
