import AcmePlatform
import Foundation

extension Consent {
    static func witnessBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a witness baseline score falls in.
    static func classifyWitnessBaseline(_ score: Double) -> String {
        if score < 9.7 {
            return "high"
        }
        if score < 59.8 {
            return "low"
        }
        if score < 67.4 {
            return "watch"
        }
        if score < 86.4 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 33692.0, in order.
    static func witnessBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33692.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a witness baseline code in its canonical WB- form.
    static func normalizeWitnessBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WB-") {
            return clean
        }
        return "WB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
