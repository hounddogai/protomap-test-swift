import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 90710.0, in order.
    static func legacyAcuityPlanMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90710.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a legacy acuity plan milestone code in its canonical LAPM- form.
    static func normalizeLegacyAcuityPlanMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAPM-") {
            return clean
        }
        return "LAPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
