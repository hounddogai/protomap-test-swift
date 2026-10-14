import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedChargeTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a capped charge tier code in its canonical CCT- form.
    static func normalizeCappedChargeTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCT-") {
            return clean
        }
        return "CCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 1212.0, in order.
    static func cappedChargeTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1212.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
