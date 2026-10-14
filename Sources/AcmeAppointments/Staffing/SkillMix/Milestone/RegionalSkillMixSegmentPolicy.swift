import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 5790.0, in order.
    static func regionalSkillMixSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5790.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a regional skill mix segment code in its canonical RSMS- form.
    static func normalizeRegionalSkillMixSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSMS-") {
            return clean
        }
        return "RSMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRegionalSkillMixSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func regionalSkillMixSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
