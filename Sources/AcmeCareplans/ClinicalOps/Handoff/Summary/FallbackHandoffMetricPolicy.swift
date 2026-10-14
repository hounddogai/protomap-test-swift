import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a fallback handoff metric code in its canonical FHM- form.
    static func normalizeFallbackHandoffMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FHM-") {
            return clean
        }
        return "FHM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackHandoffMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 69341.0, in order.
    static func fallbackHandoffMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69341.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
