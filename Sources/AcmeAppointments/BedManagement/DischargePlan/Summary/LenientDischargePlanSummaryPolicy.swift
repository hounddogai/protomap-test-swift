import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 29942.0, in order.
    static func lenientDischargePlanSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29942.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient discharge plan summary code in its canonical LDPS- form.
    static func normalizeLenientDischargePlanSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDPS-") {
            return clean
        }
        return "LDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
