import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan audit code in its canonical DPA- form.
    static func normalizeDischargePlanAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPA-") {
            return clean
        }
        return "DPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 88446.0, in order.
    static func dischargePlanAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88446.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
