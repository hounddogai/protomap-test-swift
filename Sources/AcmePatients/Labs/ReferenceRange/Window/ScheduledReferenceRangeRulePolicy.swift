import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 46088.0, in order.
    static func scheduledReferenceRangeRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46088.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeScheduledReferenceRangeRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledReferenceRangeRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a scheduled reference range rule code in its canonical SRRR- form.
    static func normalizeScheduledReferenceRangeRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRRR-") {
            return clean
        }
        return "SRRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
