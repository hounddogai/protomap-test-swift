import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a seasonal formulary segment code in its canonical SFS- form.
    static func normalizeSeasonalFormularySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFS-") {
            return clean
        }
        return "SFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 68860.0, in order.
    static func seasonalFormularySegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68860.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal formulary segment score falls in.
    static func classifySeasonalFormularySegment(_ score: Double) -> String {
        if score < 38.4 {
            return "medium"
        }
        if score < 85.2 {
            return "watch"
        }
        return "low"
    }
}
