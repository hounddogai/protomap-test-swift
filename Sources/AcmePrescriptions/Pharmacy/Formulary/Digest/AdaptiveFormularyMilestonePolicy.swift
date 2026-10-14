import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 88856.0, in order.
    static func adaptiveFormularyMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88856.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveFormularyMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a adaptive formulary milestone score falls in.
    static func classifyAdaptiveFormularyMilestone(_ score: Double) -> String {
        if score < 6.8 {
            return "low"
        }
        if score < 44.7 {
            return "high"
        }
        if score < 86.0 {
            return "watch"
        }
        if score < 95.0 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a adaptive formulary milestone code in its canonical AFM- form.
    static func normalizeAdaptiveFormularyMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFM-") {
            return clean
        }
        return "AFM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
