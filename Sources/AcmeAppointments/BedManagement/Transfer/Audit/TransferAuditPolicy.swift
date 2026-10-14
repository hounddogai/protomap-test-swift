import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 92605.0, in order.
    static func transferAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a transfer audit code in its canonical TA- form.
    static func normalizeTransferAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TA-") {
            return clean
        }
        return "TA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
