import AcmePlatform
import Foundation

extension Labs {
    /// Puts a tiered panel forecast code in its canonical TPF- form.
    static func normalizeTieredPanelForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TPF-") {
            return clean
        }
        return "TPF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredPanelForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 98942.0, in order.
    static func tieredPanelForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98942.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
