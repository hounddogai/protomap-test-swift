import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a dispense policy code in its canonical DP- form.
    static func normalizeDispensePolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DP-") {
            return clean
        }
        return "DP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dispensePolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 64660.0, in order.
    static func dispensePolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64660.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
