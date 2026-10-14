import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 28760.0, in order.
    static func legacyAcuityPlanSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28760.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyAcuityPlanSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a legacy acuity plan summary code in its canonical LAPS- form.
    static func normalizeLegacyAcuityPlanSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAPS-") {
            return clean
        }
        return "LAPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy acuity plan summary score falls in.
    static func classifyLegacyAcuityPlanSummary(_ score: Double) -> String {
        if score < 36.3 {
            return "critical"
        }
        if score < 82.3 {
            return "watch"
        }
        return "low"
    }
}
