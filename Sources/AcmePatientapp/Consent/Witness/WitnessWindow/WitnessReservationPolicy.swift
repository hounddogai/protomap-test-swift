import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness reservation code in its canonical WR- form.
    static func normalizeWitnessReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WR-") {
            return clean
        }
        return "WR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func witnessReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 56285.0, in order.
    static func witnessReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 56285.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
