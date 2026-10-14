import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 77245.0, in order.
    static func floatPoolRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77245.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a float pool rollup code in its canonical FPR- form.
    static func normalizeFloatPoolRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPR-") {
            return clean
        }
        return "FPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
