import AcmePlatform
import Foundation

extension Imaging {
    static func studyRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a study rule code in its canonical SR- form.
    static func normalizeStudyRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SR-") {
            return clean
        }
        return "SR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 9744.0, in order.
    static func studyRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9744.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a study rule score falls in.
    static func classifyStudyRule(_ score: Double) -> String {
        if score < 32.5 {
            return "minimal"
        }
        if score < 43.2 {
            return "elevated"
        }
        return "critical"
    }
}
