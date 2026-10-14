import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a weighted acuity plan budget code in its canonical WAPB- form.
    static func normalizeWeightedAcuityPlanBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAPB-") {
            return clean
        }
        return "WAPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 47633.0, in order.
    static func weightedAcuityPlanBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47633.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedAcuityPlanBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
