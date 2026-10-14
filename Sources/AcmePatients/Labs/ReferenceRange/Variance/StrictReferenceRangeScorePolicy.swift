import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 40968.0, in order.
    static func strictReferenceRangeScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40968.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a strict reference range score code in its canonical SRRS- form.
    static func normalizeStrictReferenceRangeScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRRS-") {
            return clean
        }
        return "SRRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
