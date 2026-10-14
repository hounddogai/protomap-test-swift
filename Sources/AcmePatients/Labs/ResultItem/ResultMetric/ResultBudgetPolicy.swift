import AcmePlatform
import Foundation

extension Labs {
    static func resultBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a result budget score falls in.
    static func classifyResultBudget(_ score: Double) -> String {
        if score < 63.2 {
            return "medium"
        }
        if score < 86.5 {
            return "minimal"
        }
        if score < 88.1 {
            return "ok"
        }
        if score < 97.3 {
            return "critical"
        }
        return "elevated"
    }

    /// Puts a result budget code in its canonical RB- form.
    static func normalizeResultBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 49478.0, in order.
    static func resultBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49478.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
