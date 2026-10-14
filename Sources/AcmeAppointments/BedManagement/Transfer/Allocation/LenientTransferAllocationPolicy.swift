import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 71734.0, in order.
    static func lenientTransferAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71734.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient transfer allocation code in its canonical LTA- form.
    static func normalizeLenientTransferAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LTA-") {
            return clean
        }
        return "LTA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
