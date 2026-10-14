import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 44149.0, in order.
    static func eligibilityMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44149.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a eligibility metric code in its canonical EM- form.
    static func normalizeEligibilityMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EM-") {
            return clean
        }
        return "EM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a eligibility metric score falls in.
    static func classifyEligibilityMetric(_ score: Double) -> String {
        if score < 34.2 {
            return "high"
        }
        if score < 57.7 {
            return "minimal"
        }
        if score < 91.2 {
            return "medium"
        }
        return "ok"
    }
}
