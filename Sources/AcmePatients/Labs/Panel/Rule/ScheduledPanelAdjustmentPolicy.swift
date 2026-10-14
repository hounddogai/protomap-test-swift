import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a scheduled panel adjustment score falls in.
    static func classifyScheduledPanelAdjustment(_ score: Double) -> String {
        if score < 11.8 {
            return "watch"
        }
        if score < 44.6 {
            return "elevated"
        }
        if score < 55.2 {
            return "low"
        }
        if score < 60.8 {
            return "high"
        }
        return "minimal"
    }

    static func scheduledPanelAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 35996.0, in order.
    static func scheduledPanelAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35996.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a scheduled panel adjustment code in its canonical SPA- form.
    static func normalizeScheduledPanelAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPA-") {
            return clean
        }
        return "SPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
