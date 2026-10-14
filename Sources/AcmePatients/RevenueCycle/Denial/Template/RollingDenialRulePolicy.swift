import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a rolling denial rule score falls in.
    static func classifyRollingDenialRule(_ score: Double) -> String {
        if score < 26.1 {
            return "medium"
        }
        if score < 26.3 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a rolling denial rule code in its canonical RDR- form.
    static func normalizeRollingDenialRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDR-") {
            return clean
        }
        return "RDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 49403.0, in order.
    static func rollingDenialRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49403.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingDenialRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
