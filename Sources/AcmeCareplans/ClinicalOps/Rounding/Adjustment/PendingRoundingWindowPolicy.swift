import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 67868.0, in order.
    static func pendingRoundingWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67868.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a pending rounding window code in its canonical PRW- form.
    static func normalizePendingRoundingWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRW-") {
            return clean
        }
        return "PRW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
