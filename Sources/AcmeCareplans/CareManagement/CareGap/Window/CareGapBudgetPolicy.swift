import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a care gap budget code in its canonical CGB- form.
    static func normalizeCareGapBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGB-") {
            return clean
        }
        return "CGB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 80675.0, in order.
    static func careGapBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80675.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care gap budget score falls in.
    static func classifyCareGapBudget(_ score: Double) -> String {
        if score < 61.9 {
            return "elevated"
        }
        if score < 87.9 {
            return "critical"
        }
        return "watch"
    }

    static func careGapBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
