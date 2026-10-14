import AcmePlatform
import Foundation

extension Referrals {
    static func seasonalEligibilityEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 63044.0, in order.
    static func seasonalEligibilityEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63044.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal eligibility estimate code in its canonical SEE- form.
    static func normalizeSeasonalEligibilityEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SEE-") {
            return clean
        }
        return "SEE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
