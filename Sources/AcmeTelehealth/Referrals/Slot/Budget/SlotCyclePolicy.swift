import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot cycle code in its canonical SC- form.
    static func normalizeSlotCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SC-") {
            return clean
        }
        return "SC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 83196.0, in order.
    static func slotCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83196.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
