import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot quota code in its canonical SQ- form.
    static func normalizeSlotQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SQ-") {
            return clean
        }
        return "SQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 35004.0, in order.
    static func slotQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35004.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
