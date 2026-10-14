import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 84833.0, in order.
    static func seasonalAccessionAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84833.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal accession adjustment code in its canonical SAA- form.
    static func normalizeSeasonalAccessionAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAA-") {
            return clean
        }
        return "SAA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalAccessionAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal accession adjustment score falls in.
    static func classifySeasonalAccessionAdjustment(_ score: Double) -> String {
        if score < 5.4 {
            return "elevated"
        }
        if score < 20.2 {
            return "critical"
        }
        if score < 27.0 {
            return "minimal"
        }
        if score < 61.4 {
            return "low"
        }
        return "medium"
    }
}
