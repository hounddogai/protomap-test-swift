import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 10207.0, in order.
    static func cappedStatementExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10207.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped statement exception score falls in.
    static func classifyCappedStatementException(_ score: Double) -> String {
        if score < 8.0 {
            return "low"
        }
        if score < 42.1 {
            return "high"
        }
        if score < 82.5 {
            return "ok"
        }
        if score < 93.3 {
            return "medium"
        }
        return "critical"
    }

    /// Puts a capped statement exception code in its canonical CSE- form.
    static func normalizeCappedStatementExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSE-") {
            return clean
        }
        return "CSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedStatementExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
