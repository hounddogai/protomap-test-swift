import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 85560.0, in order.
    static func seasonalClosureEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85560.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal closure entry code in its canonical SCE- form.
    static func normalizeSeasonalClosureEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCE-") {
            return clean
        }
        return "SCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
