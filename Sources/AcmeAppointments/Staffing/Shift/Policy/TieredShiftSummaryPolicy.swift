import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 31315.0, in order.
    static func tieredShiftSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31315.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered shift summary code in its canonical TSS- form.
    static func normalizeTieredShiftSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TSS-") {
            return clean
        }
        return "TSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
