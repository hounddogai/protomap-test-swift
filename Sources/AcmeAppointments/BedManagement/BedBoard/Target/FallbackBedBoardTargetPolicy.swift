import AcmePlatform
import Foundation

extension BedManagement {
    static func fallbackBedBoardTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.02
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a fallback bed board target code in its canonical FBBT- form.
    static func normalizeFallbackBedBoardTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FBBT-") {
            return clean
        }
        return "FBBT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 98916.0, in order.
    static func fallbackBedBoardTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98916.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
