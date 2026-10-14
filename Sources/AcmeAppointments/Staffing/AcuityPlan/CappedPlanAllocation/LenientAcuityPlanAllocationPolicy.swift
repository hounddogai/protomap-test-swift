import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 74442.0, in order.
    static func lenientAcuityPlanAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74442.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient acuity plan allocation code in its canonical LAPA- form.
    static func normalizeLenientAcuityPlanAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAPA-") {
            return clean
        }
        return "LAPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
