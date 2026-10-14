import AcmePlatform
import Foundation

extension Referrals {
    static func followUpTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 41162.0, in order.
    static func followUpTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41162.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a follow up target code in its canonical FUT- form.
    static func normalizeFollowUpTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUT-") {
            return clean
        }
        return "FUT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
