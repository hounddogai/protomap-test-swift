import AcmePlatform
import Foundation

extension Labs {
    /// Puts a tiered accession profile code in its canonical TAP- form.
    static func normalizeTieredAccessionProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TAP-") {
            return clean
        }
        return "TAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 10224.0, in order.
    static func tieredAccessionProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10224.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
