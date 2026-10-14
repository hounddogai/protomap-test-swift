import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a seasonal study metric code in its canonical SSM- form.
    static func normalizeSeasonalStudyMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSM-") {
            return clean
        }
        return "SSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 58274.0, in order.
    static func seasonalStudyMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58274.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a seasonal study metric score falls in.
    static func classifySeasonalStudyMetric(_ score: Double) -> String {
        if score < 21.0 {
            return "high"
        }
        if score < 57.5 {
            return "low"
        }
        if score < 91.9 {
            return "minimal"
        }
        return "watch"
    }
}
