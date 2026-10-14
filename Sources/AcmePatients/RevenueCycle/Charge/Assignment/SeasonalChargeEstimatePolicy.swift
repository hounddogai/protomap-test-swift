import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a seasonal charge estimate code in its canonical SCE- form.
    static func normalizeSeasonalChargeEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCE-") {
            return clean
        }
        return "SCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 47340.0, in order.
    static func seasonalChargeEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47340.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
