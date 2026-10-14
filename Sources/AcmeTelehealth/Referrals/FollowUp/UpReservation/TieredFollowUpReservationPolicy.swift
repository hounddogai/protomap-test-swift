import AcmePlatform
import Foundation

extension Referrals {
    static func tieredFollowUpReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 64080.0, in order.
    static func tieredFollowUpReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64080.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered follow up reservation code in its canonical TFUR- form.
    static func normalizeTieredFollowUpReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TFUR-") {
            return clean
        }
        return "TFUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
