import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a capped substitution baseline code in its canonical CSB- form.
    static func normalizeCappedSubstitutionBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSB-") {
            return clean
        }
        return "CSB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped substitution baseline score falls in.
    static func classifyCappedSubstitutionBaseline(_ score: Double) -> String {
        if score < 8.0 {
            return "elevated"
        }
        if score < 27.0 {
            return "high"
        }
        if score < 64.5 {
            return "ok"
        }
        if score < 66.8 {
            return "minimal"
        }
        return "low"
    }

    static func cappedSubstitutionBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 58131.0, in order.
    static func cappedSubstitutionBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58131.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
