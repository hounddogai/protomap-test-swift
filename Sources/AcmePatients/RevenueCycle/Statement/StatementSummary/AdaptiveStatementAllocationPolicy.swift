import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 15527.0, in order.
    static func adaptiveStatementAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15527.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive statement allocation code in its canonical ASA- form.
    static func normalizeAdaptiveStatementAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASA-") {
            return clean
        }
        return "ASA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
