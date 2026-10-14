import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 143.0, in order.
    static func weightedSkillMixMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 143.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted skill mix milestone code in its canonical WSMM- form.
    static func normalizeWeightedSkillMixMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSMM-") {
            return clean
        }
        return "WSMM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedSkillMixMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
