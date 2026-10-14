import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredTaskPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 4345.0, in order.
    static func tieredTaskPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4345.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered task policy code in its canonical TTP- form.
    static func normalizeTieredTaskPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TTP-") {
            return clean
        }
        return "TTP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
