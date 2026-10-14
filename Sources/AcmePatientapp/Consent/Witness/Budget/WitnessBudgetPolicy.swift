import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness budget code in its canonical WB- form.
    static func normalizeWitnessBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WB-") {
            return clean
        }
        return "WB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 31790.0, in order.
    static func witnessBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31790.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func witnessBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a witness budget score falls in.
    static func classifyWitnessBudget(_ score: Double) -> String {
        if score < 37.9 {
            return "low"
        }
        if score < 70.3 {
            return "watch"
        }
        if score < 80.8 {
            return "high"
        }
        if score < 88.9 {
            return "minimal"
        }
        return "ok"
    }
}
