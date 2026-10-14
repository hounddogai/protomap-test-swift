import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalInteractionAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 49748.0, in order.
    static func globalInteractionAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49748.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a global interaction assignment code in its canonical GIA- form.
    static func normalizeGlobalInteractionAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GIA-") {
            return clean
        }
        return "GIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
